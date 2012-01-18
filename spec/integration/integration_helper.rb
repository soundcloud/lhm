#
#  Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
#  Schmidt
#

require File.expand_path(File.dirname(__FILE__)) + "/../bootstrap"

require 'active_record'
require 'lhm/table'
require 'lhm/sql_helper'

module IntegrationHelper
  attr_accessor :connection

  #
  # Connectivity
  #

  def connect_master!
    @connection = connect!(3306)
  end

  def connect_slave!
    @connection = connect!(3307)
  end

  def connect!(port)
    ActiveRecord::Base.establish_connection(
      :adapter => 'mysql',
      :host => '127.0.0.1',
      :database => 'lhm',
      :username => '',
      :port => port
    )

    ActiveRecord::Base.connection
  end

  def select_one(*args)
    connection.select_one(*args)
  end

  def select_value(*args)
    connection.select_value(*args)
  end

  def execute(*args)
    connection.execute(*args)
  end

  def slave(&block)
    if master_slave_mode?
      connect_slave!

      # need to wait for the slave to catch up. a better method would be to
      # check the master binlog position and wait for the slave to catch up
      # to that position.
      sleep 1
    end

    yield block

    if master_slave_mode?
      connect_master!
    end
  end

  #
  # Test Data
  #

  def fixture(name)
    File.read($fixtures.join("#{ name }.ddl"))
  end

  def table_create(fixture_name)
    execute "drop table if exists `#{ fixture_name }`"
    execute fixture(fixture_name)
    table_read(fixture_name)
  end

  def table_read(fixture_name)
    Lhm::Table.parse(fixture_name, connection)
  end

  def table_exists?(table)
    connection.table_exists?(table.name)
  end

  #
  # Database Helpers
  #

  def count(table, column, value)
    query = "select count(*) from #{ table } where #{ column } = '#{ value }'"
    select_value(query).to_i
  end

  def count_all(table)
    query = "select count(*) from #{ table }"
    select_value(query).to_i
  end

  def key?(table_name, cols, type = :non_unique)
    non_unique = type == :non_unique ? 1 : 0
    key_name = Lhm::SqlHelper.idx_name(table_name, cols)
    query = "show indexes in #{ table_name } where key_name = '#{ key_name }' and non_unique = #{ non_unique }"
    !!select_value(query)
  end

  #
  # Environment
  #

  def master_slave_mode?
    !!ENV["MASTER_SLAVE"]
  end
end
