# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require 'lhm/command'
require 'lhm/sql_helper'
require 'timeout'

module Lhm
  class Entangler
    include Command
    include SqlHelper

    TABLES_WITH_LONG_QUERIES = %w(designs campaigns campaign_roots tags orders).freeze
    MAX_RUNNING_SECONDS = 3

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
      kill_long_running_queries_on_origin_table if special_origin?
      entangle.each do |stmt|
        execute_with_timeout(stmt, MAX_RUNNING_SECONDS)
      end
    end

    def after
      kill_long_running_queries_on_origin_table if special_origin?
      untangle.each do |stmt|
        execute_with_timeout(stmt, MAX_RUNNING_SECONDS)
      end
    end

    def revert
      after
    end

    private

    def special_origin?
      TABLES_WITH_LONG_QUERIES.include? @origin.name
    end

    def kill_long_running_queries_on_origin_table!
      return unless ENV['LHM_KILL_LONG_RUNNING_QUERIES'] == 'true'
      3.times do
        long_running_queries(@origin.name).each do |id, query, duration|
          Lhm.logger.info "Action on table #{table_name} detected; killing #{duration}-second query: #{query}."
          @connection.execute("KILL #{id}")
        end
        sleep(7)
      end
    end

    def long_running_queries(table_name)
      result = @connection.execute <<-SQL.strip_heredoc
        SELECT ID, INFO, TIME FROM INFORMATION_SCHEMA.PROCESSLIST
        WHERE command <> 'Sleep'
          AND INFO LIKE '%`#{table_name}`%'
          AND INFO NOT LIKE "%INFORMATION_SCHEMA.PROCESSLIST%"
          AND TIME > 10 ORDER BY TIME DESC
      SQL
      result.to_a.compact
    end

    def execute_with_timeout(stmt, sec = MAX_RUNNING_SECONDS)
      lock_wait_timeout = @connection.execute("SHOW SESSION VARIABLES WHERE VARIABLE_NAME='LOCK_WAIT_TIMEOUT'").to_a.flatten[1].to_i
      @connection.execute("SET SESSION LOCK_WAIT_TIMEOUT=#{sec}")
      Lhm.logger.info "Set transaction timeout (SESSION LOCK_WAIT_TIMEOUT) to #{sec} seconds."
      @connection.execute(tagged(stmt))
      @connection.execute("SET SESSION LOCK_WAIT_TIMEOUT=#{lock_wait_timeout}")
      Lhm.logger.info "Set transaction timeout (SESSION LOCK_WAIT_TIMEOUT) back to #{lock_wait_timeout} seconds."
    rescue => error
      puts "Transaction took more than #{sec} seconds to run.. ABORT! #{error}"
    end

    def strip(sql)
      sql.strip.gsub(/\n */, "\n")
    end
  end
end
