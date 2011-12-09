#
#  copyright (c) 2011, soundcloud ltd., rany keddo, tobias bielohlawek, tobias
#  schmidt
#

require File.expand_path(File.dirname(__FILE__)) + "/../bootstrap"

module IntegrationHelper
  delegate :select_one, :select_value, :execute :to => :connection

  def connect!
    ActiveRecord::Base.establish_connection(
      :adapter => 'mysql',
      :database => 'large_hadron_migrator',
      :username => '',
      :host => 'localhost'
    )

    ActiveRecord::Migration.verbose = !!ENV["VERBOSE"]
  end

  def connection
    ActiveRecord::Base.connection
  end

  def fixture(name)
    File.read($fixtures.join(name))
  end

  def schema_columns(table, name, type)
    db = connection.current_database

    select_values %Q{
      select column_name
        from information_schema.columns
       where table_name = "#{table}"
         and table_schema = "#{db}"
         and column_name = "#{name}"
         and data_type = "#{type}"
    }
  end
end

connect!
