module Lhm
  module Printer

    class Output
      def write(message)
        print message
      end
    end

    class Base

      def initialize
        @output = Output.new
      end
    end

    class Percentage < Base

      def initialize
        super
        @max_length = 0
      end

      def notify(lowest, highest)
        return if highest == 0
        message = "%.2f%% (#{lowest}/#{highest}) complete" % (lowest.to_f / highest * 100.0)
        write(message)
      end

      def end
        write("100% complete")
        @output.write "\n"
      end

      private
      def write(message)
        if (extra = @max_length - message.length) < 0
          @max_length = message.length
          extra = 0
        end

        @output.write "\r#{message}" + (" " * extra)
      end
    end

    class Dot < Base
      def notify(lowest = nil, highest = nil)
        @output.write "."
      end

      def end
        @output.write "\n"
      end
    end
  end
end
