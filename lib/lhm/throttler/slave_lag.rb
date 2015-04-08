module Lhm
  module Throttler
    class SlaveLag
      include Command

      INITIAL_TIMEOUT = 0.1
      DEFAULT_STRIDE = 40_000
      DEFAULT_MAX_ALLOWED_LAG = 10

      MAX_TIMEOUT = INITIAL_TIMEOUT * 1024

      attr_accessor :timeout_seconds
      attr_accessor :stride
      attr_accessor :allowed_lag

      def initialize(options = {})
        raise ArgumentError, 'You must provide a valid :connection option when using the slave lag throttler' unless options[:connection] && options[:connection].respond_to?(:execute)

        @timeout_seconds = INITIAL_TIMEOUT
        @stride = options[:stride] || DEFAULT_STRIDE
        @allowed_lag = options[:allowed_lag] || DEFAULT_MAX_ALLOWED_LAG
        @connection = options[:connection]
        @slave_connections = {}
      end

      def execute
        sleep(throttle_seconds)
      end

      private

      SQL_SELECT_SLAVE_HOSTS = "SELECT host FROM information_schema.processlist WHERE command='Binlog Dump'"
      SQL_SELECT_MAX_SLAVE_LAG = 'SHOW SLAVE STATUS'

      private_constant :SQL_SELECT_SLAVE_HOSTS, :SQL_SELECT_MAX_SLAVE_LAG

      def throttle_seconds
        lag = max_current_slave_lag

        if lag > @allowed_lag && @timeout_seconds < MAX_TIMEOUT
          Lhm.logger.info("Increasing timeout between strides from #{@timeout_seconds} to #{@timeout_seconds * 2} because #{lag} seconds of slave lag detected is greater than the maximum of #{@allowed_lag} seconds allowed.")
          @timeout_seconds = @timeout_seconds * 2
        elsif lag <= @allowed_lag && @timeout_seconds > INITIAL_TIMEOUT
          Lhm.logger.info("Decreasing timeout between strides from #{@timeout_seconds} to #{@timeout_seconds / 2} because #{lag} seconds of slave lag detected is less than or equal to the #{@allowed_lag} seconds allowed.")
          @timeout_seconds = @timeout_seconds / 2
        else
          @timeout_seconds
        end
      end

      def slave_hosts
        get_slaves.map { |slave_host| slave_host.partition(':')[0] }
          .delete_if { |slave| slave == 'localhost' || slave == '127.0.0.1' }
      end

      def get_slaves
        @connection.select_values(SQL_SELECT_SLAVE_HOSTS)
      end

      def max_current_slave_lag
        slave_hosts.map { |slave| slave_lag(slave) }.flatten.push(0).max
      end

      def slave_lag(slave)
        conn = slave_connection(slave)
        if conn.respond_to?(:exec_query)
          result = conn.exec_query(SQL_SELECT_MAX_SLAVE_LAG)
          result.map { |row| row['Seconds_Behind_Master'].to_i }
        else
          result = conn.execute(SQL_SELECT_MAX_SLAVE_LAG)
          fetch_slave_seconds(result)
        end
      rescue Error => e
        raise Lhm::Error, "Unable to connect and/or query slave to determine slave lag. Migration aborting because of: #{e}"
      end

      def slave_connection(slave)
        adapter_method = defined?(Mysql2) ? 'mysql2_connection' : 'mysql_connection'
        config = ActiveRecord::Base.connection_pool.spec.config.dup
        config[:host] = slave
        ActiveRecord::Base.send(adapter_method, config)
      end

      # This method fetch the Seconds_Behind_Master, when exec_query is no available, on AR 2.3.
      def fetch_slave_seconds(result)
        return 0 unless result.class.to_s == 'Mysql::Result'
        keys = []
        result.each_hash do |h|
          keys << h['Seconds_Behind_Master'].to_i
        end
        keys
      end

    end
  end
end
