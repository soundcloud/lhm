# Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
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
    @migration = Lhm::Migration.new(@origin, @destination, @start)
  end

  it "should name archive" do
    stamp = "%Y_%m_%d_%H_%M_%S_#{ "%03d" % (@start.usec / 1000) }"
    @migration.archive_name.must_equal "lhma_#{ @start.strftime(stamp) }_origin"
  end
end
