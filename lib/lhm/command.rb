#
#  Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
#  Schmidt
#
#  Apply a change to the database.
#

module Lhm
  module Command
    def self.included(base)
      base.send :attr_reader, :connection
    end

    #
    # Command Interface
    #

    def validate; end

    def revert; end

    def run(&block)
      validate

      if(block_given?)
        before
        block.call(self)
        after
      else
        execute
      end
    end

  private

    def execute
      raise NotImplementedError.new(self.class.name)
    end

    def before
      raise NotImplementedError.new(self.class.name)
    end

    def after
      raise NotImplementedError.new(self.class.name)
    end

    def table?(table_name)
      @connection.table_exists?(table_name)
    end

    def error(msg)
      raise Exception.new("#{ self.class }: #{ msg }")
    end

    def sql(statements)
      Array(statements).each { |stmt| @connection.execute(stmt) }
    rescue ActiveRecord::StatementInvalid, Mysql::Error => e
      revert
      error e.message
    end
  end
end

