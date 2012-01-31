# Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

module Lhm
  module SqlHelper
    extend self

    def annotation
      "/* large hadron migration */"
    end

    def idx_name(table_name, cols)
      column_names = column_definition(cols).map(&:first)
      "index_#{ table_name }_on_#{ column_names.join("_and_") }"
    end

    def idx_spec(cols)
      column_definition(cols).map do |name, length|
        "`#{ name }`#{ length }"
      end.join(', ')
    end

    def table?(table_name)
      connection.table_exists?(table_name)
    end

    def sql(statements)
      [statements].flatten.each do |statement|
        connection.execute(tagged(statement))
      end
    rescue ActiveRecord::StatementInvalid, Mysql::Error => e
      error e.message
    end

    def update(statements)
      [statements].flatten.inject(0) do |memo, statement|
        memo += connection.update(tagged(statement))
      end
    rescue ActiveRecord::StatementInvalid, Mysql::Error => e
      error e.message
    end

  private

    def tagged(statement)
      "#{ statement } #{ SqlHelper.annotation }"
    end

    def column_definition(cols)
      Array(cols).map do |column|
        column.to_s.match(/`?([^\(]+)`?(\([^\)]+\))?/).captures
      end
    end
  end
end
