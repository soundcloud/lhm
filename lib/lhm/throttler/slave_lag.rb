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
        raise ArgumentError, "You must provide a valid :connection option when using the slave lag throttler" unless options[:connection] && options[:connection].respond_to?(:execute)

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
      SQL_SELECT_MAX_SLAVE_LAG = "SHOW SLAVE STATUS"

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
        get_slaves.map { |slave_host| slave_host.partition(":")[0] }
          .delete_if { |slave| slave == "localhost" || slave == "127.0.0.1" }
      end

      def get_slaves
        @connection.execute(SQL_SELECT_SLAVE_HOSTS).map(&:first)
      end

      def max_current_slave_lag
        slave_hosts.map { |slave| slave_lag(slave) }.flatten.push(0).max
      end

      def slave_lag(slave)
        result = slave_connection(slave).execute(SQL_SELECT_MAX_SLAVE_LAG)
        result.each(:as => :hash).map { |row| row["Seconds_Behind_Master"].to_i }
      rescue Error => e
        raise Lhm::Error, "Unable to connect and/or query slave to determine slave lag. Migration aborting because of: #{e}"
      end

      def slave_connection(slave)
        adapter_method = defined?(Mysql2) ? 'mysql2_connection' : 'mysql_connection'

        config = { :host => slave,
                   :port => ActiveRecord::Base.connection_config[:port],
                   :username => ActiveRecord::Base.connection_config[:username],
                   :password => ActiveRecord::Base.connection_config[:password],
                   :database => ActiveRecord::Base.connection_config[:database] }

        Lhm::Connection.new(ActiveRecord::Base.send(adapter_method, config))
      end
    end
  end
end
