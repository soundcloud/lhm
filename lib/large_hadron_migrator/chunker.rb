#
#  copyright (c) 2011, soundcloud ltd., rany keddo, tobias bielohlawek, tobias
#  schmidt
#

module LargeHadronMigrator
  class Chunker
    def initialize(table, stride = 100_000, throttle = 100)
      @table = table
      @stride = stride
      @throttle = throttle
      @start = Time.now
    end

    def chunk(entangler)
      chunks.times do |n|
        yield(bottom(n), top(n, entangler.last)) && sleep(throttle_seconds)
      end
    end

    def chunks(last)
      (last / @stride.to_f).ceil
    end

    def bottom(chunk)
      (chunk - 1) * @stride + 1
    end

    def top(chunk, last)
      [chunk * @stride, last].min
    end

    private

      def throttle_seconds
        @throttle / 100.0
      end
  end
end

