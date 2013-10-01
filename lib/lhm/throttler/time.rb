module Lhm
  module Throttler
    class Time
      include Command

      attr_accessor :timeout_seconds

      def initialize(options = {})
        @timeout_seconds = options[:delay] || 0.1
      end

      def execute
        sleep timeout_seconds
      end
    end

    class LegacyTime < Time
      def initialize(throttle)
        @timeout_seconds = throttle / 1000.0
      end
    end
  end
end
