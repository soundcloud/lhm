# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt
require 'lhm/command'
require 'lhm/sql_helper'
require 'lhm/printer'

module Lhm
  class Chunker
    include Command
    include SqlHelper

    attr_reader :connection

    # Copy from origin to destination in chunks of size `stride`.
    # Use the `throttler` class to sleep between each stride.
    def initialize(migration, connection = nil, options = {})
      @migration = migration
      @connection = connection
      if @throttler = options[:throttler]
        @throttler.connection = @connection if @throttler.respond_to?(:connection=)
      end
      @start = options[:start] || ENV['LHM_RESUME_AT']&.to_i || select_start
      @limit = options[:limit] || select_limit
      @printer = options[:printer] || Printer::Percentage.new
    end

    def execute
      return unless @start && @limit
      @next_to_insert = @start
      while @next_to_insert < @limit || (@start == @limit)
        stride = @throttler.stride
        affected_rows = @connection.update(copy(bottom, top(stride)))

        if @throttler && affected_rows > 0
          @throttler.run
        end

        @printer.notify(bottom, @limit)
        @next_to_insert = top(stride) + 1
        break if @start == @limit
      end
      @printer.end
    end

    private

    def bottom
      @next_to_insert
    end

    def top(stride)
      [(@next_to_insert + stride - 1), @limit].min
    end

    def copy(lowest, highest)
      "insert ignore into `#{ destination_name }` (#{ destination_columns }) " \
      "select #{ origin_columns } from `#{ origin_name }` " \
      "#{ conditions } `#{ origin_name }`.`id` between #{ lowest } and #{ highest }"
    end

    def select_start
      start = connection.select_value("select min(id) from `#{ origin_name }`")
      start ? start.to_i : nil
    end

    def select_limit
      limit = connection.select_value("select max(id) from `#{ origin_name }`")
      limit ? limit.to_i : nil
    end

    # XXX this is extremely brittle and doesn't work when filter contains more
    # than one SQL clause, e.g. "where ... group by foo". Before making any
    # more changes here, please consider either:
    #
    # 1. Letting users only specify part of defined clauses (i.e. don't allow
    # `filter` on Migrator to accept both WHERE and INNER JOIN
    # 2. Changing query building so that it uses structured data rather than
    # strings until the last possible moment.
    def conditions
      if @migration.conditions
        @migration.conditions.
          sub(/\)\Z/, '').
          # put any where conditions in parens
          sub(/where\s(\w.*)\Z/, 'where (\\1)') + ' and'
      else
        'where'
      end
    end

    def destination_name
      @migration.destination.name
    end

    def origin_name
      @migration.origin.name
    end

    def origin_columns
      @origin_columns ||= @migration.intersection.origin.typed(origin_name)
    end

    def destination_columns
      @destination_columns ||= @migration.intersection.destination.joined
    end

    def validate
      if @start && @limit && @start > @limit
        error('impossible chunk options (limit must be greater than start)')
      end
    end
  end
end
