# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
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

    attr_reader :name, :statements, :connection, :conditions, :renames

    def initialize(table, connection = nil)
      @connection = connection
      @origin = table
      @name = table.destination_name
      @statements = []
      @renames = {}
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
      ddl('alter table `%s` add column `%s` %s' % [@name, name, definition])
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
      ddl('alter table `%s` modify column `%s` %s' % [@name, name, definition])
    end

    # Rename an existing column.
    #
    # @example
    #
    #   Lhm.change_table(:users) do |m|
    #     m.rename_column(:login, :username)
    #   end
    #
    # @param [String] old Name of the column to change
    # @param [String] nu New name to use for the column
    def rename_column(old, nu)
      col = @origin.columns[old.to_s]

      definition = col[:type]
      definition += ' NOT NULL' unless col[:is_nullable]
      definition += " DEFAULT #{@connection.quote_value(col[:column_default])}" if col[:column_default]

      ddl('alter table `%s` change column `%s` `%s` %s' % [@name, old, nu, definition])
      @renames[old.to_s] = nu.to_s
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
      ddl('alter table `%s` drop `%s`' % [@name, name])
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
    # @param [String, Symbol] index_name
    #   Optional name of the index to be created
    def add_index(columns, index_name = nil)
      ddl(index_ddl(columns, false, index_name))
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
    # @param [String, Symbol] index_name
    #   Optional name of the index to be created
    def add_unique_index(columns, index_name = nil)
      ddl(index_ddl(columns, true, index_name))
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
    # @param [String, Symbol] index_name
    #   Optional name of the index to be removed
    def remove_index(columns, index_name = nil)
      columns = [columns].flatten.map(&:to_sym)
      from_origin = @origin.indices.find { |name, cols| cols.map(&:to_sym) == columns }
      index_name ||= from_origin[0] unless from_origin.nil?
      index_name ||= idx_name(@origin.name, columns)
      ddl('drop index `%s` on `%s`' % [index_name, @name])
    end

    # Add a trigger to a table
    #
    # @example
    #   Lhm.change_table(:users) do |m|
    #     m.add_trigger(:new_trigger, :before, :insert, "SET NEW.created_at = NULL;")
    #   end
    #
    # @param [String, Symbol] name The name of the trigger to create
    #
    # @param [Symbol] timing  The trigger action timing. Must be one of :before
    #   or :after to indicate that the trigger activates before or after each row
    #   to be modified.
    #
    # @param [Symbol] event Indicates the kind of operation that activates the
    #   trigger. These trigger_event values are permitted:
    #
    #   :insert - The trigger activates whenever a new row is inserted into the
    #   table; for example, through INSERT, LOAD DATA, and REPLACE statements.
    #
    #   :update - The trigger activates whenever a row is modified; for example,
    #   through UPDATE statements.
    #
    #   :delete - The trigger activates whenever a row is deleted from the table;
    #   for example, through DELETE and REPLACE statements.
    #
    # @param [String] body The statement to execute when the trigger activates.
    #
    def add_trigger(name, timing, event, body)
      unless [ :before, :after ].include? timing
        raise ArgumentError.new("Trigger timing must be one of :before, or :after. Received '#{timing}'")
      end
      unless [ :insert, :update, :delete ].include? event
        raise ArgumentError.new("Trigger event must be one of :insert, :update, or :delete. Received '#{event}'")
      end
      ddl("create trigger `%s` %s %s on `%s` for each row %s" % [name, timing, event, @name, body])
    end

    # Remove a trigger from the database
    #
    # @example
    #   Lhm.change_table(:users) do |m|
    #     m.remove_trigger(:trigger_x)
    #   end
    #
    # @param [String, Symbol] trigger_name The name of the trigger to remove
    #
    def remove_trigger(trigger_name)
      ddl("drop trigger `#{trigger_name}`")
    end

    # Filter the data that is copied into the new table by the provided SQL.
    # This SQL will be inserted into the copy directly after the "from"
    # statement - so be sure to use inner/outer join syntax and not cross joins.
    #
    # @example Add a conditions filter to the migration.
    #   Lhm.change_table(:sounds) do |m|
    #     m.filter("inner join users on users.`id` = sounds.`user_id` and sounds.`public` = 1")
    #   end
    #
    # @param [ String ] sql The sql filter.
    #
    # @return [ String ] The sql filter.
    def filter(sql)
      @conditions = sql
    end

  private

    def validate
      unless @connection.table_exists?(@origin.name)
        error("could not find origin table #{ @origin.name }")
      end

      unless @origin.satisfies_primary_key?
        error('origin does not satisfy primary key requirements')
      end

      dest = @origin.destination_name

      if @connection.table_exists?(dest)
        error("#{ dest } should not exist; not cleaned up from previous run?")
      end
    end

    def execute
      destination_create
      @connection.sql(@statements)
      Migration.new(@origin, destination_read, conditions, renames)
    end

    def destination_create
      @connection.destination_create(@origin)
    end

    def destination_read
      Table.parse(@origin.destination_name, connection)
    end

    def index_ddl(cols, unique = nil, index_name = nil)
      assert_valid_idx_name(index_name)
      type = unique ? 'unique index' : 'index'
      index_name ||= idx_name(@origin.name, cols)
      parts = [type, index_name, @name, idx_spec(cols)]
      'create %s `%s` on `%s` (%s)' % parts
    end

    def assert_valid_idx_name(index_name)
      if index_name && !(index_name.is_a?(String) || index_name.is_a?(Symbol))
        raise ArgumentError, 'index_name must be a string or symbol'
      end
    end
  end
end
