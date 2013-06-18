module Lhm
  require 'lhm/sql_helper'

  class Connection
    def self.new(adapter)
      if defined?(DataMapper) && adapter.is_a?(DataMapper::Adapters::AbstractAdapter)
        DataMapperConnection.new(adapter)
      elsif defined?(ActiveRecord)
        ActiveRecordConnection.new(adapter)
      else
        raise 'Neither DataMapper nor ActiveRecord found.'
      end
    end

    class DataMapperConnection
      include SqlHelper

      def initialize(adapter)
        @adapter       = adapter
        @database_name = adapter.options['database'] || adapter.options['path'][1..-1]
      end

      def sql(statements)
        [statements].flatten.each do |statement|
          execute(tagged(statement))
        end
      end

      def show_create(table_name)
        sql = "show create table `#{ table_name }`"
        select_one(sql).values.last
      end

      def current_database
        @database_name
      end

      def update(statements)
        [statements].flatten.inject(0) do |memo, statement|
          result = @adapter.execute(tagged(statement))
          memo  += result.affected_rows
        end
      end

      def select_all(sql)
        @adapter.select(sql).to_a
      end

      def select_one(sql)
        select_all(sql).first
      end

      def select_values(sql)
        select_all(sql)
      end

      def select_value(sql)
        select_one(sql)
      end

      def destination_create(origin)
        sql(origin.destination_ddl)
      end

      def execute(sql)
        @adapter.execute(sql)
      end

      def table_exists?(table_name)
        !!select_one(%Q{
          select *
            from information_schema.tables
           where table_schema = '#{ @database_name }'
             and table_name = '#{ table_name }'
        })
      end
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
        sql(origin.destination_ddl)
      end

      def execute(sql)
        @adapter.execute(sql)
      end

      def table_exists?(table_name)
        @adapter.table_exists?(table_name)
      end
    end
  end
end
