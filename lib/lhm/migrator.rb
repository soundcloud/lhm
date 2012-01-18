#
#  Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
#  Schmidt
#
#  Copies existing schema and applies changes using alter on the empty table.
#  `run` returns a Migration which can be used for the remaining process.
#

require 'lhm/command'
require 'lhm/migration'
require 'lhm/sql_helper'
require 'lhm/table'

module Lhm
  class Migrator
    include Command
    include SqlHelper

    attr_reader :name, :statements, :connection

    def initialize(table, connection = nil)
      @connection = connection
      @origin = table
      @name = table.destination_name
      @statements = []
    end

    def ddl(statement)
      statements << statement
    end

    #
    # Add a column to a table:
    #
    #   Lhm.change_table("users") do |t|
    #     t.add_column(:logins, "INT(12) DEFAULT '0'")
    #   end
    #

    def add_column(name, definition = "")
      ddl = "alter table `%s` add column `%s` %s" % [@name, name, definition]
      statements << ddl
    end

    #
    # Remove a column from a table:
    #
    #   Lhm.change_table("users") do |t|
    #     t.remove_column(:comment)
    #   end
    #

    def remove_column(name)
      ddl = "alter table `%s` drop `%s`" % [@name, name]
      statements << ddl
    end

    #
    # Add an index to a table:
    #
    #  Lhm.change_table("users") do |t|
    #    t.add_index([:comment, :created_at])
    #  end
    #

    def add_index(cols)
      statements << index_ddl(cols)
    end

    #
    # Add a unique index to a table:
    #
    #  Lhm.change_table("users") do |t|
    #    t.add_unique_index([:comment, :created_at])
    #  end
    #

    def add_unique_index(cols)
      statements << index_ddl(cols, :unique)
    end

    #
    # Remove an index from a table
    #
    #   Lhm.change_table("users") do |t|
    #     t.remove_index(:username, :created_at)
    #   end
    #

    def remove_index(cols)
      ddl = "drop index `%s` on `%s`" % [idx_name(@origin.name, cols), @name]
      statements << ddl
    end

  private

    def validate
      unless table?(@origin.name)
        error("could not find origin table #{ @origin.name }")
      end

      unless @origin.satisfies_primary_key?
        error("origin does not satisfy primary key requirements")
      end

      dest = @origin.destination_name

      if table?(dest)
        error("#{ dest } should not exist; not cleaned up from previous run?")
      end
    end

    def execute
      destination_create
      sql(@statements)
      Migration.new(@origin, destination_read)
    end

    def destination_create
      original = "CREATE TABLE `#{ @origin.name }`"
      replacement = "CREATE TABLE `#{ @origin.destination_name }`"

      sql(@origin.ddl.gsub(original, replacement))
    end

    def destination_read
      Table.parse(@origin.destination_name, connection)
    end

    def index_ddl(cols, unique = nil)
      type = unique ? "unique index" : "index"
      parts = [type, idx_name(@origin.name, cols), @name, idx_spec(cols)]
      "create %s `%s` on `%s` (%s)" % parts
    end
  end
end
