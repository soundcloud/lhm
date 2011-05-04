#
#  Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek
#

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'active_record'
require 'large_hadron_migration'
require 'spec'
require 'spec/autorun'

ActiveRecord::Base.establish_connection(
  :adapter => 'mysql',
  :database => 'large_hadron_migration',
  :username => 'root',
  :password => '',
  :host => 'localhost'
)

module SpecHelper
  def connection
    ActiveRecord::Base.connection
  end

  def sql(args)
    connection.execute(args)
  end

  def recreate
    sql "drop database large_hadron_migration"
    sql "create database large_hadron_migration character set = 'UTF8'"

    ActiveRecord::Base.connection.reconnect!
  end

  def flunk(msg)
    raise Spec::Expectations::ExpectationNotMetError.new(msg)
  end

  def table(name)
    ActiveRecord::Schema.define do
      create_table(name) do |t|
        yield t
      end
    end

    name
  end

  #
  #  can't be arsed with rspec matchers
  #

  def truthiness_column(table, name, type)
    results = connection.select_values %Q{
      select column_name
        from information_schema.columns
       where table_name = "%s"
         and table_schema = "%s"
         and column_name = "%s"
         and data_type = "%s"
    } % [table, connection.current_database, name, type]

    if results.empty?
      flunk "truthiness column not defined as: %s:%s:%s" % [
        table,
        name,
        type
      ]
    end
  end

  def truthiness_rows(table_name1, table_name2, offset = 0, limit = 1000)
    res_1 = sql("SELECT * FROM #{table_name1} ORDER BY id ASC LIMIT #{limit} OFFSET #{offset}")
    res_2 = sql("SELECT * FROM #{table_name2} ORDER BY id ASC LIMIT #{limit} OFFSET #{offset}")

    limit.times do |i|
      res_1_hash = res_1.fetch_hash
      res_2_hash = res_2.fetch_hash

      if res_1_hash.nil? || res_2_hash.nil?
        flunk("truthiness rows failed: Expected #{limit} rows, but only #{i} found")
      end

      res_1_hash.keys.each do |key|
        flunk("truthiness rows failed: #{key} is not same") unless res_1_hash[key] == res_2_hash[key]
      end
    end

  end

end

# Mock Rails Environment
class Rails
  class << self
    def env
      self
    end

    def development?
      false
    end

    def production?
      true
    end

    def test?
      false
    end
  end
end
