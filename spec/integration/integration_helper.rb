#
#  Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
#  Schmidt
#

require File.expand_path(File.dirname(__FILE__)) + "/../bootstrap"

require 'active_record'
require 'lhm/table'

module IntegrationHelper

  #
  # Connectivity
  #

  def connect!
    ActiveRecord::Base.establish_connection(
      :adapter => 'mysql',
      :database => 'lhm',
      :username => '',
      :host => 'localhost'
    )

    ActiveRecord::Migration.verbose = !!ENV["VERBOSE"]
  end

  def connection
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

  def key?(table, cols)
    query = "show indexes in #{ table.name } where key_name = '#{ table.idx_name(cols) }'"
    !!select_value(query)
  end
end

