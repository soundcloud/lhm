# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require 'lhm/sql_helper'

module Lhm
  class Table
    attr_reader :name, :columns, :indices, :constraints, :pk, :ddl

    def initialize(name, pk = "id", ddl = nil)
      @name = name
      @columns = {}
      @indices = {}
      @constraints = {}
      @pk = pk
      @ddl = ddl
    end

    def satisfies_primary_key?
      @pk == "id"
    end

    def destination_name
      "lhmn_#{ @name }"
    end

    def self.parse(table_name, connection)
      Parser.new(table_name, connection).parse
    end

    def destination_ddl
      original    = %r{CREATE TABLE ("|`)#{ name }\1}
      # Strange substitutions are happening when I put this in the string directly
      repl = '\1'
      replacement = %Q{CREATE TABLE #{repl}#{ destination_name }#{repl}}

      dest = ddl
      dest.gsub!(original, replacement)

      foreign_keys = constraints.select {|col, c| !c[:referenced_column].nil?}

      foreign_keys.keys.each_with_index do |key, i|
        original = foreign_keys[key][:name]
        # Offset the new key names by the total size so they cannot overlap
        replacement = original.sub(/(_\d+)?$/, "_#{foreign_keys.size + i + 1}")
        dest.gsub!(original, replacement)
      end

      dest
    end

    class Parser
      include SqlHelper

      def initialize(table_name, connection)
        @table_name = table_name.to_s
        @schema_name = connection.current_database
        @connection = connection
      end

      def ddl
        @connection.show_create(@table_name)
      end

      def parse
        schema = read_information_schema

        Table.new(@table_name, extract_primary_key(schema), ddl).tap do |table|
          schema.each do |defn|
            column_name    = struct_key(defn, "COLUMN_NAME")
            column_type    = struct_key(defn, "COLUMN_TYPE")
            is_nullable    = struct_key(defn, "IS_NULLABLE")
            column_default = struct_key(defn, "COLUMN_DEFAULT")
            table.columns[defn[column_name]] = {
              :type => defn[column_type],
              :is_nullable => defn[is_nullable],
              :column_default => defn[column_default]
            }
          end

          extract_indices(read_indices).each do |idx, columns|
            table.indices[idx] = columns
          end

          extract_constraints(read_constraints).each do |data|
            table.constraints[data[:column]] = data
          end
        end
      end

    private

      def read_information_schema
        @connection.select_all %Q{
          select *
            from information_schema.columns
           where table_name = '#{ @table_name }'
             and table_schema = '#{ @schema_name }'
        }
      end

      def read_indices
        @connection.select_all %Q{
          show indexes from `#{ @schema_name }`.`#{ @table_name }`
         where key_name != 'PRIMARY'
        }
      end

      def extract_indices(indices)
        indices.
          map do |row|
            key_name = struct_key(row, "Key_name")
            column_name = struct_key(row, "COLUMN_NAME")
            [row[key_name], row[column_name]]
          end.
          inject(Hash.new { |h, k| h[k] = []}) do |memo, (idx, column)|
            memo[idx] << column
            memo
          end
      end

      def read_constraints
        @connection.select_all %Q{
          select *
            from information_schema.key_column_usage
           where table_name = '#{ @table_name }'
             and table_schema = '#{ @schema_name }'
        }
      end

      def extract_constraints(constraints)
        constraints.map do |row|
          constraint_name = struct_key(row, 'CONSTRAINT_NAME')
          column_name = struct_key(row, "COLUMN_NAME")
          ref_table_name = struct_key(row, 'REFERENCED_TABLE_NAME')
          ref_col_name = struct_key(row, 'REFERENCED_COLUMN_NAME')

          {
            :name              => row[constraint_name],
            :column            => row[column_name],
            :referenced_table  => row[ref_table_name],
            :referenced_column => row[ref_col_name]
          }
        end
      end

      def extract_primary_key(schema)
        cols = schema.select do |defn|
          column_key = struct_key(defn, "COLUMN_KEY")
          defn[column_key] == "PRI"
        end

        keys = cols.map do |defn|
          column_name = struct_key(defn, "COLUMN_NAME")
          defn[column_name]
        end

        keys.length == 1 ? keys.first : keys
      end
    end
  end
end
