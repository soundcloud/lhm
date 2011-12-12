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
    end

    def up_to(limit)
      traversable_chunks_up_to(limit).times do |n|
        yield(bottom(n + 1), top(n + 1, limit)) && sleep(throttle_seconds)
      end
    end

    def traversable_chunks_up_to(limit)
      (limit / @stride.to_f).ceil
    end

    def bottom(chunk)
      (chunk - 1) * @stride + 1
    end

    def top(chunk, limit)
      [chunk * @stride, limit].min
    end

    private

      def throttle_seconds
        @throttle / 100.0
      end
  end
end

