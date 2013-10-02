module Lhm
  module Throttler
    class Time
      include Command

      DEFAULT_TIMEOUT = 0.1
      DEFAULT_STRIDE = 40_000

      attr_accessor :timeout_seconds
      attr_accessor :stride

      def initialize(options = {})
        @timeout_seconds = options[:delay] || DEFAULT_TIMEOUT
        @stride = options[:stride] || DEFAULT_STRIDE
      end

      def execute
        sleep timeout_seconds
      end
    end

    class LegacyTime < Time
      def initialize(timeout, stride)
        @timeout_seconds = timeout / 1000.0
        @stride = stride
      end
    end
  end
end
