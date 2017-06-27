# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require File.expand_path(File.dirname(__FILE__)) + '/integration_helper'

require 'lhm/table'
require 'lhm/migration'
require 'lhm/locked_switcher'

describe Lhm::LockedSwitcher do
  include IntegrationHelper

  before(:each) do
    connect_master!
    @old_logger = Lhm.logger
    Lhm.logger = Logger.new('/dev/null')
  end

  after(:each) do
    Lhm.logger = @old_logger
  end

  describe 'switching' do
    before(:each) do
      @origin = table_create('origin')
      @destination = table_create('destination')
      @migration = Lhm::Migration.new(@origin, @destination)
    end

    it 'rename origin to archive' do
      switcher = Lhm::LockedSwitcher.new(@migration, connection)
      switcher.run

      slave do
        data_source_exists?(@origin).must_equal true
        table_read(@migration.archive_name).columns.keys.must_include 'origin'
      end
    end

    it 'rename destination to origin' do
      switcher = Lhm::LockedSwitcher.new(@migration, connection)
      switcher.run

      slave do
        data_source_exists?(@destination).must_equal false
        table_read(@origin.name).columns.keys.must_include 'destination'
      end
    end
  end
end
