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
      @start = options[:start] || select_start
      @limit = options[:limit] || select_limit
      @printer = options[:printer] || Printer::Percentage.new
      @retry_on_deadlock = retry_on_deadlock(options.with_indifferent_access)
      @retry_attempts = retry_attempts(options.with_indifferent_access)
      @retry_wait_time = retry_wait_time(options.with_indifferent_access)
    end

    def execute
      return unless @start && @limit

      retries = 0

      @next_to_insert = @start
      while @next_to_insert < @limit || (@start == @limit)
        stride = @throttler.stride

        begin
          affected_rows = @connection.update(copy(bottom, top(stride)))
        rescue ActiveRecord::StatementInvalid => err
          if err.message.downcase.index('deadlock').nil?
            raise
            return
          end

          if !@retry_on_deadlock
            raise
            return
          end

          retries = retries + 1
          if retries == (@retry_attempts + 1)
            puts "Crossed #{@retry_attempts} attempts. Raising exception ..."
            raise
            return
          else
            puts "Caught exception: #{err.message}."
            print "Attempt #{retries} of #{@retry_attempts} "
            puts "after sleeping for #{@retry_wait_time} seconds ..."
            sleep @retry_wait_time
            next
          end
        end

        retries = 0

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

    def retry_on_deadlock(options)
      if options.has_key?(:retry_on_deadlock) &&
         ( options[:retry_on_deadlock].is_a?(TrueClass) ||
           options[:retry_on_deadlock].is_a?(FalseClass) )

        return options[:retry_on_deadlock]
      end

      return true
    end

    def retry_attempts(options)
      if options.has_key?(:retry_attempts) &&
         options[:retry_attempts].is_a?(Numeric)

        return options[:retry_attempts]
      end

      return 10
    end

    def retry_wait_time(options)
      if options.has_key?(:retry_wait_time) &&
         options[:retry_wait_time].is_a?(Numeric)

        return options[:retry_wait_time]
      end

      return 10
    end
  end
end
