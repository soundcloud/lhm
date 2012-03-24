# Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require 'lhm/sql_helper'

module Lhm
  class Table
    attr_reader :name, :columns, :indices, :pk, :ddl

    def initialize(name, pk = "id", ddl = nil)
      @name = name
      @columns = {}
      @indices = {}
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

    class Parser
      include SqlHelper

      def initialize(table_name, connection)
        @table_name = table_name.to_s
        @schema_name = connection.current_database
        @connection = connection
      end

      def ddl
        sql = "show create table `#{ @table_name }`"
        results = []
        @connection.execute(sql).each(:as => :array) do |r|
          results << r
        end
        results.first.last
      end

      def parse
        schema = read_information_schema

        Table.new(@table_name, extract_primary_key(schema), ddl).tap do |table|
          schema.each do |defn|
            table.columns[defn["COLUMN_NAME"]] = {
              :type => defn["COLUMN_TYPE"],
              :is_nullable => defn["IS_NULLABLE"],
              :column_default => defn["COLUMN_DEFAULT"]
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
           where table_name = "#{ @table_name }"
             and table_schema = "#{ @schema_name }"
        }
      end

      def read_indices
        @connection.select_all %Q{
          show indexes from `#{ @schema_name }`.`#{ @table_name }`
         where key_name != "PRIMARY"
        }
      end

      def extract_indices(indices)
        indices.map { |row| [row["Key_name"], row["Column_name"]] }.
          inject(Hash.new { |h, k| h[k] = []}) do |memo, (idx, column)|
            memo[idx] << column
            memo
          end
      end

      def extract_primary_key(schema)
        cols = schema.select { |defn| defn["COLUMN_KEY"] == "PRI" }
        keys = cols.map { |defn| defn["COLUMN_NAME"] }
        keys.length == 1 ? keys.first : keys
      end
    end
  end
end
