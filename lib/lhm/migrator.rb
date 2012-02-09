# Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require 'lhm/command'
require 'lhm/migration'
require 'lhm/sql_helper'
require 'lhm/table'

module Lhm
  # Copies existing schema and applies changes using alter on the empty table.
  # `run` returns a Migration which can be used for the remaining process.
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

    # Alter a table with a custom statement
    #
    # @example
    #
    #   Lhm.change_table(:users) do |m|
    #     m.ddl("ALTER TABLE #{m.name} ADD COLUMN age INT(11)")
    #   end
    #
    # @param [String] statement SQL alter statement
    # @note
    #
    #   Don't write the table name directly into the statement. Use the #name
    #   getter instead, because the alter statement will be executed against a
    #   temporary table.
    #
    def ddl(statement)
      statements << statement
    end

    # Add a column to a table
    #
    # @example
    #
    #   Lhm.change_table(:users) do |m|
    #     m.add_column(:comment, "VARCHAR(12) DEFAULT '0'")
    #   end
    #
    # @param [String] name Name of the column to add
    # @param [String] definition Valid SQL column definition
    def add_column(name, definition)
      ddl("alter table `%s` add column `%s` %s" % [@name, name, definition])
    end

    # Change an existing column to a new definition
    #
    # @example
    #
    #   Lhm.change_table(:users) do |m|
    #     m.change_column(:comment, "VARCHAR(12) DEFAULT '0' NOT NULL")
    #   end
    #
    # @param [String] name Name of the column to change
    # @param [String] definition Valid SQL column definition
    def change_column(name, definition)
      remove_column(name)
      add_column(name, definition)
    end

    # Remove a column from a table
    #
    # @example
    #
    #   Lhm.change_table(:users) do |m|
    #     m.remove_column(:comment)
    #   end
    #
    # @param [String] name Name of the column to delete
    def remove_column(name)
      ddl("alter table `%s` drop `%s`" % [@name, name])
    end

    # Add an index to a table
    #
    # @example
    #
    #   Lhm.change_table(:users) do |m|
    #     m.add_index(:comment)
    #     m.add_index([:username, :created_at])
    #     m.add_index("comment(10)")
    #   end
    #
    # @param [String, Symbol, Array<String, Symbol>] columns
    #   A column name given as String or Symbol. An Array of Strings or Symbols
    #   for compound indexes. It's possible to pass a length limit.
    def add_index(columns)
      ddl(index_ddl(columns))
    end

    # Add a unique index to a table
    #
    # @example
    #
    #   Lhm.change_table(:users) do |m|
    #     m.add_unique_index(:comment)
    #     m.add_unique_index([:username, :created_at])
    #     m.add_unique_index("comment(10)")
    #   end
    #
    # @param [String, Symbol, Array<String, Symbol>] columns
    #   A column name given as String or Symbol. An Array of Strings or Symbols
    #   for compound indexes. It's possible to pass a length limit.
    def add_unique_index(columns)
      ddl(index_ddl(columns, :unique))
    end

    # Remove an index from a table
    #
    # @example
    #
    #   Lhm.change_table(:users) do |m|
    #     m.remove_index(:comment)
    #     m.remove_index([:username, :created_at])
    #   end
    #
    # @param [String, Symbol, Array<String, Symbol>] columns
    #   A column name given as String or Symbol. An Array of Strings or Symbols
    #   for compound indexes.
    def remove_index(columns)
      ddl("drop index `%s` on `%s`" % [idx_name(@origin.name, columns), @name])
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
