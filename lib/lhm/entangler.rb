# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require 'lhm/command'
require 'lhm/sql_helper'

module Lhm
  class Entangler
    include Command
    include SqlHelper

    TABLES_WITH_LONG_QUERIES = %w(designs campaigns campaign_roots tags orders).freeze
    LONG_QUERY_TIME_THRESHOLD = 10
    INITIALIZATION_DELAY = 2
    TRIGGER_MAXIMUM_DURATION = 2
    SESSION_WAIT_LOCK_TIMEOUT = LONG_QUERY_TIME_THRESHOLD + INITIALIZATION_DELAY + TRIGGER_MAXIMUM_DURATION

    attr_reader :connection

    # Creates entanglement between two tables. All creates, updates and deletes
    # to origin will be repeated on the destination table.
    def initialize(migration, connection = nil)
      @intersection = migration.intersection
      @origin = migration.origin
      @destination = migration.destination
      @connection = connection
    end

    def entangle
      [
        create_delete_trigger,
        create_insert_trigger,
        create_update_trigger
      ]
    end

    def untangle
      [
        "drop trigger if exists `#{ trigger(:del) }`",
        "drop trigger if exists `#{ trigger(:ins) }`",
        "drop trigger if exists `#{ trigger(:upd) }`"
      ]
    end

    def create_insert_trigger
      strip %Q{
        create trigger `#{ trigger(:ins) }`
        after insert on `#{ @origin.name }` for each row
        replace into `#{ @destination.name }` (#{ @intersection.destination.joined }) #{ SqlHelper.annotation }
        values (#{ @intersection.origin.typed('NEW') })
      }
    end

    def create_update_trigger
      strip %Q{
        create trigger `#{ trigger(:upd) }`
        after update on `#{ @origin.name }` for each row
        replace into `#{ @destination.name }` (#{ @intersection.destination.joined }) #{ SqlHelper.annotation }
        values (#{ @intersection.origin.typed('NEW') })
      }
    end

    def create_delete_trigger
      strip %Q{
        create trigger `#{ trigger(:del) }`
        after delete on `#{ @origin.name }` for each row
        delete ignore from `#{ @destination.name }` #{ SqlHelper.annotation }
        where `#{ @destination.name }`.`id` = OLD.`id`
      }
    end

    def trigger(type)
      "lhmt_#{ type }_#{ @origin.name }"[0...64]
    end

    def validate
      unless @connection.table_exists?(@origin.name)
        error("#{ @origin.name } does not exist")
      end

      unless @connection.table_exists?(@destination.name)
        error("#{ @destination.name } does not exist")
      end
    end

    def before
      return if ENV['LHM_RESUME_AT'].present?

      kill_long_running_queries_on_origin_table! if special_origin?
      with_transaction_timeout do
        entangle.each do |stmt|
          kill_long_running_queries_during_transaction do
            @connection.execute(tagged(stmt))
          end
        end
      end
    end

    def after
      kill_long_running_queries_on_origin_table! if special_origin?
      with_transaction_timeout do
        untangle.each do |stmt|
          kill_long_running_queries_during_transaction do
            @connection.execute(tagged(stmt))
          end
        end
      end
    end

    def revert
      after
    end

    def special_origin?
      TABLES_WITH_LONG_QUERIES.include? @origin.name
    end

    def kill_long_running_queries_on_origin_table!(connection: nil)
      return unless ENV['LHM_KILL_LONG_RUNNING_QUERIES'] == 'true'
      connection ||= @connection
      long_running_queries(@origin.name, connection: connection).each do |id, query, duration|
        Lhm.logger.info "Action on table #{@origin.name} detected; killing #{duration}-second query: #{query}."
        begin
          connection.execute("KILL #{id};")
        rescue => e
          if e.message =~ /Unknown thread id/
            Lhm.logger.info "Race condition detected. Process to kill no longer exists. Proceeding despite the following error: #{e.message}"
          else
            raise e
          end
        end
      end
    end

    def long_running_queries(table_name, connection: nil)
      connection ||= @connection
      result = connection.execute <<-SQL.strip_heredoc
        SELECT ID, INFO, TIME FROM INFORMATION_SCHEMA.PROCESSLIST
        WHERE command <> 'Sleep'
          AND INFO LIKE '%`#{table_name}`%'
          AND INFO NOT LIKE '%TRIGGER%'
          AND INFO NOT LIKE "%INFORMATION_SCHEMA.PROCESSLIST%"
          AND TIME > '#{LONG_QUERY_TIME_THRESHOLD}'
      SQL
      result.to_a.compact
    end

    def kill_long_running_queries_during_transaction
      t = Thread.new do
        if ENV['LHM_KILL_LONG_RUNNING_QUERIES'] == 'true'
          # the goal of this thread is to wait until long running queries that started between
          # #kill_long_running_queries_on_origin_table! and trigger creation
          # to pass the threshold time and then kill them
          sleep(LONG_QUERY_TIME_THRESHOLD + INITIALIZATION_DELAY)
          new_connection = ActiveRecord::Base.connection

          kill_long_running_queries_on_origin_table!(connection: new_connection)
        end
      end
      yield
      t.join
    end

    def with_transaction_timeout
      lock_wait_timeout = @connection.execute("SHOW SESSION VARIABLES WHERE VARIABLE_NAME='LOCK_WAIT_TIMEOUT'").to_a.flatten[1].to_i
      @connection.execute("SET SESSION LOCK_WAIT_TIMEOUT=#{SESSION_WAIT_LOCK_TIMEOUT}")
      Lhm.logger.info "Set transaction timeout (SESSION LOCK_WAIT_TIMEOUT) to #{SESSION_WAIT_LOCK_TIMEOUT} seconds."
      yield
    rescue => e
      if e.message =~ /Lock wait timeout exceeded/
        error("Transaction took more than #{SESSION_WAIT_LOCK_TIMEOUT} seconds (SESSION_WAIT_LOCK_TIMEOUT) to run.. ABORT! #{e.message}")
      else
        error(e.message)
      end
    ensure
      @connection.execute("SET SESSION LOCK_WAIT_TIMEOUT=#{lock_wait_timeout}")
      Lhm.logger.info "Set transaction timeout (SESSION LOCK_WAIT_TIMEOUT) back to #{lock_wait_timeout} seconds."
    end

    private

    def strip(sql)
      sql.strip.gsub(/\n */, "\n")
    end
  end
end
