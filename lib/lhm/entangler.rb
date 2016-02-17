# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require 'lhm/command'
require 'lhm/sql_helper'

module Lhm
  class Entangler
    include Command
    include SqlHelper

    attr_reader :connection

    # Creates entanglement between two tables. All creates, updates and deletes
    # to origin will be repeated on the destination table.
    def initialize(migration, connection = nil, options = {})
      @intersection = migration.intersection
      @origin = migration.origin
      @destination = migration.destination
      @connection = connection
      @triggers = options[:triggers] || [:delete, :insert, :update]
    end

    def entangle
      triggers = []

      triggers << create_delete_trigger if @triggers.include?(:delete)
      triggers << create_insert_trigger if @triggers.include?(:insert)
      triggers << create_update_trigger if @triggers.include?(:update)

      triggers
    end

    def untangle
      triggers = []

      triggers << "drop trigger if exists `#{ trigger(:del) }`" if @triggers.include?(:delete)
      triggers << "drop trigger if exists `#{ trigger(:ins) }`" if @triggers.include?(:insert)
      triggers << "drop trigger if exists `#{ trigger(:upd) }`" if @triggers.include?(:update)

      triggers
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
      entangle.each do |stmt|
        @connection.execute(tagged(stmt))
      end
    end

    def after
      untangle.each do |stmt|
        @connection.execute(tagged(stmt))
      end
    end

    def revert
      after
    end

    private

    def strip(sql)
      sql.strip.gsub(/\n */, "\n")
    end
  end
end
