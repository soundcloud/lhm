# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'

require 'lhm/table'
require 'lhm/migration'

describe Lhm::Migration do
  include UnitHelper

  before(:each) do
    @start = Time.now
    @origin = Lhm::Table.new("origin")
    @destination = Lhm::Table.new("destination")
    @migration = Lhm::Migration.new(@origin, @destination, "id", nil, @start)
  end

  it "should name archive" do
    stamp = "%Y_%m_%d_%H_%M_%S_#{ "%03d" % (@start.usec / 1000) }"
    @migration.archive_name.must_equal "lhma_#{ @start.strftime(stamp) }_origin"
  end

  it "should limit table name to 64 characters" do
    migration = Lhm::Migration.new(OpenStruct.new(:name => "a_very_very_long_table_name_that_should_make_the_LHMA_table_go_over_64_chars"), nil, "id")
    migration.archive_name.size == 64
  end
end
