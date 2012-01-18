#
#  Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
#  Schmidt
#
#  Apply a change to the database.
#

module Lhm
  class Error < StandardError
  end

  module Command
    def self.included(base)
      base.send :attr_reader, :connection
    end

    def run(&block)
      validate

      if(block_given?)
        before
        block.call(self)
        after
      else
        execute
      end
    rescue
      revert
      raise
    end

  private

    def validate
    end

    def revert
    end

    def execute
      raise NotImplementedError.new(self.class.name)
    end

    def before
    end

    def after
    end

    def table?(table_name)
      @connection.table_exists?(table_name)
    end

    def error(msg)
      raise Error.new(msg)
    end

    def sql(statements)
      [statements].flatten.each { |statement| @connection.execute(statement) }
    rescue ActiveRecord::StatementInvalid, Mysql::Error => e
      error e.message
    end

    def update(statements)
      [statements].flatten.inject(0) do |memo, statement|
        memo += @connection.update(statement)
      end
    rescue ActiveRecord::StatementInvalid, Mysql::Error => e
      error e.message
    end
  end
end

