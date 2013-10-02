# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require File.expand_path(File.dirname(__FILE__)) + '/integration_helper'

require 'lhm/table'
require 'lhm/migration'
require 'lhm/atomic_switcher'

describe Lhm::AtomicSwitcher do
  include IntegrationHelper

  before(:each) { connect_master! }

  describe "switching" do
    before(:each) do
      @origin      = table_create("origin")
      @destination = table_create("destination")
      @migration   = Lhm::Migration.new(@origin, @destination, "id")
    end

    it "rename origin to archive" do
      switcher = Lhm::AtomicSwitcher.new(@migration, connection)
      switcher.run

      slave do
        table_exists?(@origin).must_equal true
        table_read(@migration.archive_name).columns.keys.must_include "origin"
      end
    end

    it "rename destination to origin" do
      switcher = Lhm::AtomicSwitcher.new(@migration, connection)
      switcher.run

      slave do
        table_exists?(@destination).must_equal false
        table_read(@origin.name).columns.keys.must_include "destination"
      end
    end
  end
end
