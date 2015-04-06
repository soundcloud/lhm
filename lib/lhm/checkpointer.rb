# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require 'lhm/command'
require 'lhm/sql_helper'

module Lhm
  class Checkpointer
    include Command
    include SqlHelper

    # Checkpoints progress
    def initialize(connection, options = {})
      @connection = connection
      @checkpoint = options[:checkpoint]
      @start = options[:start]

      @checkpoint_table = 'lhm_checkpoint'
    end

    def checkpoint(last)
      last ||= 0

      sql = %Q{
        insert into `#{ @checkpoint_table }` values ( 'last', #{ last.to_i } ) on duplicate key update value =  #{ last.to_i }
      }

      @connection.execute(sql)
    end

    def start
      start = @connection.select_value("select value from `#{ @checkpoint_table }`")
      start ? start.to_i : nil
    end

    def create_checkpoint_table
      sql = %Q{
        create table `#{ @checkpoint_table }` ( `name` varchar(8) UNIQUE, `value` bigint )
      }

      @connection.execute(tagged(sql))
    end

    def validate
      if !@checkpoint && @connection.table_exists?(@checkpoint_table)
        error("checkpoint table exists but checkpointing is not enabled")
      end
    end

    def before
      return unless @checkpoint

      unless @connection.table_exists?(@checkpoint_table)
        create_checkpoint_table
        checkpoint(@start)
      end
    end

    def after
      # TODO: Should we delete the checkpoint table here?
    end

  end
end
