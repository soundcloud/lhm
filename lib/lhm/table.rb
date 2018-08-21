# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require 'lhm/sql_helper'

module Lhm
  class Table
    attr_reader :name, :columns, :indices, :pk, :ddl
    @@naming_strategy = nil
    @@default_naming_strategy = lambda { |name| "lhmn_#{ @name }" }

    def initialize(name, pk = 'id', ddl = nil)
      @name = name
      @columns = {}
      @indices = {}
      @pk = pk
      @ddl = ddl
    end

    def self.naming_strategy=(naming_strategy)
      @@naming_strategy = naming_strategy
    end

    def satisfies_id_column_requirement?
      !!((id = columns['id']) &&
        id[:type] =~ /(bigint|int)\(\d+\)/)
    end

    def destination_name
      naming_strategy = @@naming_strategy ||  @@default_naming_strategy
      naming_strategy.call(@name)
    end

    def self.parse(table_name, connection)
      Parser.new(table_name, connection).parse
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

        Table.new(@table_name, extract_primary_key(schema), ddl).tap do |table|
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
  end
end
