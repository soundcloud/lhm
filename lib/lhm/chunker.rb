#
#  Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
#  Schmidt
#

require 'lhm/migration'
require 'lhm/command'

module Lhm
  class Chunker
    include Command

    #
    # Copy from origin to destination in chunks of size `stride`. Sleeps for
    # `throttle` milliseconds between each stride.
    #

    def initialize(migration, limit = 1, connection = nil, options = {})
      @stride = options[:stride] || 40_000
      @throttle = options[:throttle] || 100
      @limit = limit
      @connection = connection
      @migration = migration
    end

    #
    # Copies chunks of size `stride`, starting from id 1 up to id `limit`.
    #

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

    def copy(lowest, highest)
      "insert ignore into `#{ @migration.destination.name }` (#{ cols.joined  }) " +
      "select #{ cols.joined } from `#{ @migration.origin.name }` " +
      "where `id` between #{ lowest } and #{ highest }"
    end

  private

    def cols
      @cols ||= @migration.intersection
    end

    def execute
      up_to(@limit) do |lowest, highest|
        print "."

        sql copy(lowest, highest)
      end
    end

    def throttle_seconds
      @throttle / 1000.0
    end
  end
end

