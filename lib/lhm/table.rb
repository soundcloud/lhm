# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require 'lhm/sql_helper'

module Lhm
  class Table
    attr_reader :schema, :name, :columns, :indices, :constraints, :pk, :ddl

    def initialize(name, schema = 'default', pk = 'id', ddl = nil)
      @name = name
      @schema = schema
      @columns = {}
      @indices = {}
      @constraints = {}
      @pk = pk
      @ddl = ddl
    end

    def satisfies_id_column_requirement?
      !!((id = columns['id']) &&
        id[:type] =~ /(bigint|int)\(\d+\)/)
    end

    def destination_name
      "lhmn_#{ @name }"
    end

    def self.parse(table_name, connection)
      Parser.new(table_name, connection).parse
    end

    def destination_ddl
      original    = %r{CREATE TABLE ("|`)#{ name }\1}
      repl = '\1'
      replacement = %Q{CREATE TABLE #{ repl }#{ destination_name }#{ repl }}

      dest = ddl
      dest.gsub!(original, replacement)

      foreign_keys = constraints.select { |col, c| !c[:referenced_column].nil? }

      foreign_keys.keys.each_with_index do |key, i|
        original = foreign_keys[key][:name]
        replacement = replacement_constraint(original)
        dest.gsub!(original, replacement)
      end

      dest
    end

    @@schema_constraints = {}

    def self.schema_constraints(schema, value = nil)
      @@schema_constraints[schema] = value if value
      @@schema_constraints[schema]
    end

    class Parser
      include SqlHelper

      def initialize(table_name, connection)
        @table_name = table_name.to_s
        @schema_name = connection.current_database
        @connection = connection
      end

      def ddl
        sql = "show create table `#{ @table_name }`"
        specification = nil
        @connection.execute(sql).each { |row| specification = row.last }
        specification
      end

      def parse
        schema = read_information_schema

        Table.new(@table_name, @schema_name, extract_primary_key(schema), ddl).tap do |table|
          schema.each do |defn|
            column_name    = struct_key(defn, 'COLUMN_NAME')
            column_type    = struct_key(defn, 'COLUMN_TYPE')
            is_nullable    = struct_key(defn, 'IS_NULLABLE')
            column_default = struct_key(defn, 'COLUMN_DEFAULT')

            table.columns[defn[column_name]] = {
              :type => defn[column_type],
              :is_nullable => defn[is_nullable],
              :column_default => defn[column_default],
            }
          end

          extract_indices(read_indices).each do |idx, columns|
            table.indices[idx] = columns
          end

          constraints = {}
          extract_constraints(read_constraints(nil)).each do |data|
            if data[:schema] == @schema_name && data[:table] == @table_name
              table.constraints[data[:column]] = data
            end
            constraints[data[:name]] = data
          end
          Table.schema_constraints(@schema_name, constraints)
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
            key_name = struct_key(row, 'Key_name')
            column_name = struct_key(row, 'COLUMN_NAME')
            [row[key_name], row[column_name]]
          end.
          inject(Hash.new { |h, k| h[k] = [] }) do |memo, (idx, column)|
            memo[idx] << column
            memo
          end
      end

      def read_constraints(table = @table_name)
        query = %Q{
          select *
            from information_schema.key_column_usage
           where table_schema = '#{ @schema_name }'
             and referenced_column_name is not null
        }
        query += %Q{
             and table_name = '#{ @table_name }'
        } if table

        @connection.select_all(query)
      end

      def extract_constraints(constraints)
        columns = %w{
          CONSTRAINT_NAME
          TABLE_SCHEMA
          TABLE_NAME
          COLUMN_NAME
          ORDINAL_POSITION
          POSITION_IN_UNIQUE_CONSTRAINT
          REFERENCED_TABLE_SCHEMA
          REFERENCED_TABLE_NAME
          REFERENCED_COLUMN_NAME
        }

        constraints.map do |row|
          result = {}
          columns.each do |c|
            sym = c.dup
            # The order of these substitutions is important
            sym.gsub!(/CONSTRAINT_/, '')
            sym.gsub!(/_NAME/, '')
            sym.gsub!(/TABLE_/, '')
            result[sym.downcase.to_sym] = row[struct_key(row, c)]
          end
          result
        end
      end

      def extract_primary_key(schema)
        cols = schema.select do |defn|
          column_key = struct_key(defn, 'COLUMN_KEY')
          defn[column_key] == 'PRI'
        end

        keys = cols.map do |defn|
          column_name = struct_key(defn, 'COLUMN_NAME')
          defn[column_name]
        end

        keys.length == 1 ? keys.first : keys
      end
    end

    private

    def replacement_constraint(name)
      (name =~ /_lhmn$/).nil? ? "#{name}_lhmn" : name.gsub(/_lhmn$/, '')
    end

  end
end
