module Lhm
  require 'lhm/sql_helper'

  class Connection
    def self.new(adapter)
      ActiveRecordConnection.new(adapter)
    end

    class ActiveRecordConnection
      include SqlHelper

      def initialize(adapter)
        @adapter       = adapter
        @database_name = @adapter.current_database
      end

      def sql(statements)
        [statements].flatten.each do |statement|
          execute(tagged(statement))
        end
      end

      def show_create(table_name)
        sql = "show create table `#{ table_name }`"
        specification = nil
        execute(sql).each { |row| specification = row.last }
        specification
      end

      def current_database
        @database_name
      end

      def update(sql)
        @adapter.update(sql)
      end

      def select_all(sql)
        @adapter.select_all(sql)
      end

      def select_one(sql)
        @adapter.select_one(sql)
      end

      def select_values(sql)
        @adapter.select_values(sql)
      end

      def select_value(sql)
        @adapter.select_value(sql)
      end

      def destination_create(origin)
        original    = %{CREATE TABLE `#{ origin.name }`}
        replacement = %{CREATE TABLE `#{ origin.destination_name }`}

        sql(origin.ddl.gsub(original, replacement))
      end

      def execute(sql)
        @adapter.execute(sql)
      end

      def table_exists?(table_name)
        @adapter.table_exists?(table_name)
      end

      def quote_value(value)
        @adapter.quote(value)
      end
    end
  end
end
