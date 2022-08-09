# Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require 'lhm/command'
require 'lhm/sql_helper'

module Lhm
  class Chunker
    include Command
    include SqlHelper

    attr_reader :connection

    # Copy from origin to destination in chunks of size `stride`. Sleeps for
    # `throttle` milliseconds between each stride.
    def initialize(migration, connection = nil, options = {})
      @migration = migration
      @connection = connection
      @stride = options[:stride] || 40_000
      @throttle = options[:throttle] || 100
      @start = options[:start] || select_start
      @limit = options[:limit] || select_limit
      @batch_mode = options.fetch(:batch_mode, true)
    end

    # Copies chunks of size `stride`, starting from `start` up to id `limit`.
    def up_to(&block)
      1.upto(traversable_chunks_size) do |n|
        yield(bottom(n), top(n))
      end
    end

    def traversable_chunks_size
      @limit && @start ? ((@limit - @start + 1) / @stride.to_f).ceil : 0
    end

    def bottom(chunk)
      (chunk - 1) * @stride + @start
    end

    def top(chunk)
      [chunk * @stride + @start - 1, @limit].min
    end

    def copy(lowest, highest)
      "insert ignore into `#{ destination_name }` (#{ columns }) " +
      "select #{ columns } from `#{ origin_name }` " +
      "where `#{ origin_primary_key }` between #{ lowest } and #{ highest }"
    end

    def copy_batchwise(select_clause)
      "insert ignore into `#{ destination_name }` (#{ columns }) " + 
      "#{select_clause}"
    end

    def select_start
      start = connection.select_value("select min(#{origin_primary_key}) from #{ origin_name }")
      start ? start.to_i : nil
    end

    def select_limit
      limit = connection.select_value("select max(#{origin_primary_key}) from #{ origin_name }")
      limit ? limit.to_i : nil
    end

    def throttle_seconds
      @throttle / 1000.0
    end

    def select_query(offset, columns_to_be_selected = nil)
      columns_to_be_selected ||= columns
      "select #{ columns_to_be_selected } from `#{ origin_name }` " +
        "where `#{origin_primary_key}` > #{offset} " +
        "and `#{origin_primary_key}` <= #{@limit} " +
        "order by #{origin_primary_key} asc limit #{@stride}"
    end

  private

    def destination_name
      @migration.destination.name
    end

    def origin_name
      @migration.origin.name
    end

    def origin_primary_key
      @migration.origin.pk
    end

    def columns
      @columns ||= @migration.intersection.joined
    end

    def validate
      if @start && @limit && @start > @limit
        error("impossible chunk options (limit must be greater than start)")
      end
    end

    def execute
      @batch_mode ? execute_batch_mode : execute_incremental_mode
    end

    def execute_incremental_mode
      up_to do |lowest, highest|
        affected_rows = @connection.update(copy(lowest, highest))

        if affected_rows > 0
          sleep(throttle_seconds)
        end

        print "."
      end
      print "\n"
    end

    def execute_batch_mode
      start_value = @start - 1
      loop do
        # Getting last id first in order to handle deletes
        # Assume, continuous ids from 1 to 20 with stride 10, and ids 5, 6 are deleted after copying first batch 1 to 10
        #   If we fetch last id after copying, start_value will become 12, and records 11, 12 will not be copied
        #   If we fetch last id before copying, start_value will be 10
        # In case of any INSERTs between the ids in first batch,
        #   start_value will not be the latest id, but because of INSERT IGNORE clause while copying
        #   it will be safely ignored
        next_primary_key_value = @connection.select_last(select_query(start_value, origin_primary_key)).to_h["#{origin_primary_key}"]
        affected_rows = @connection.update(copy_batchwise(select_query(start_value)))

        if affected_rows > 0
          sleep(throttle_seconds)
        elsif next_primary_key_value.nil? || next_primary_key_value >= @limit
          break
        end

        start_value = next_primary_key_value
        print '.'
      end
      print "\n"
    rescue => e
      print e.message
    end
  end
end
