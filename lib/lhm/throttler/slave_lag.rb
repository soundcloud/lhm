module Lhm
  module Throttler
    class SlaveLag 
      include Command

      DEFAULT_TIMEOUT = 0.1
      DEFAULT_STRIDE = 40_000
      DEFAULT_MAX_ALLOWED_LAG = 10

      MAX_TIMEOUT = DEFAULT_TIMEOUT * 1024

      attr_accessor :timeout_seconds
      attr_accessor :stride
      attr_accessor :allowed_lag

      def initialize(options = {})
        raise ArgumentError, "You must provide a valid :connection option when using the slave lag throttler" unless options[:connection]

        @timeout_seconds = DEFAULT_TIMEOUT
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
        elsif lag <= @allowed_lag && @timeout_seconds > DEFAULT_TIMEOUT
          Lhm.logger.info("Decreasing timeout between strides from #{@timeout_seconds} to #{@timeout_seconds / 2} because #{lag} seconds of slave lag detected is less than or equal to the #{@allowed_lag} seconds allowed.")
          @timeout_seconds = @timeout_seconds / 2
        else
          @timeout_seconds
        end
      end

      def slave_hosts
        slave_hosts = get_slaves
        slaves = slave_hosts.map { |slave_host| slave_host.partition(":")[0] }
        slaves.delete_if { |slave| slave == "localhost" || slave == "127.0.0.1" }
      end
   
      def get_slaves
        @connection.execute(SQL_SELECT_SLAVE_HOSTS).map(&:first)
      end  
  
      def max_current_slave_lag
        lags = [0]
        slave_hosts.each do |slave|
          lags.concat(slave_lag(slave))
        end
        lags.max
      end

      def slave_lag(slave)
        lags = []
        adapter_method = defined?(Mysql2) ? 'mysql2_connection' : 'mysql_connection'
        config = { :host => slave,
                   :port => ActiveRecord::Base.connection_config[:port],
                   :username => ActiveRecord::Base.connection_config[:username],
                   :password => ActiveRecord::Base.connection_config[:password], 
                   :database => ActiveRecord::Base.connection_config[:database]
                 }
        conn = Lhm::Connection.new(ActiveRecord::Base.send(adapter_method, config))
        result = conn.execute(SQL_SELECT_MAX_SLAVE_LAG)
        result.each(:as => :hash) {|row| lags.push( row["Seconds_Behind_Master"].to_i ) }
        lags
      rescue Error
        raise Lhm::Error, "Unable to connect and/or query slave to determine slave lag. Migration aborting."
      end
    end
  end
end