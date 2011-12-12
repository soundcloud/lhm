require 'minitest/spec'
require 'minitest/autorun'
require 'active_record'

load 'spec/fuzz/fuzz-percona'

database = {
  :adapter  => 'mysql',
  :database => 'large_hadron_migrator',
  :username => '',
  :host     => 'localhost'
}

fuzz = FuzzPercona.new(database) # .merge(:debug => true)
fuzz.run

ActiveRecord::Base.establish_connection(database)

module SpecHelper
  delegate :select_one, :select_value, :to => :connection

  def connection
    ActiveRecord::Base.connection
  end

  def select_int(sql)
    select_value(sql).to_i
  end
end

describe Fuzz do
  include SpecHelper

  it "must not lose existing data" do
    select_int("select count(*) from test where type = 'static'").must_equal fuzz.initial[:static]
  end

  it "must have repeatable reads" do
    select_int("select count(*) from test where type = 'update' and updated = 1").must_equal fuzz.changed[:update]
    select_int("select count(*) from test where type = 'delete'").must_equal(fuzz.initial[:delete] - fuzz.changed[:delete])
  end

  it "must not lose inserts" do
    select_int("select count(*) from test where type = 'load'").must_equal fuzz.changed[:insert]
  end
end
