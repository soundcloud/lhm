module Lhm
  module Throttle

    class Time
      include Command

      attr_accessor :throttle_seconds

      def initialize(options = {})
        @throttle_seconds = options[:delay] || 0.1
      end

      def execute
        sleep throttle_seconds
      end
    end

    class LegacyTime < Time

      def initialize(throttle)
        @throttle_seconds = throttle / 1000.0
      end
    end

  end
end
