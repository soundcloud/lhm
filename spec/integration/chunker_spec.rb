# Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require File.expand_path(File.dirname(__FILE__)) + '/integration_helper'

require 'lhm'
require 'lhm/table'
require 'lhm/migration'

describe Lhm::Chunker do
  include IntegrationHelper

  before(:each) { connect_master! }

  describe "copying" do
    before(:each) do
      @origin = table_create(:origin)
      @destination = table_create(:destination)
      @migration = Lhm::Migration.new(@origin, @destination)
    end

    it "should copy 23 rows from origin to destination" do
      23.times { |n| execute("insert into origin set id = '#{ n * n + 23 }'") }

      Lhm::Chunker.new(@migration, connection, { :stride => 100 }).run

      slave do
        count_all(@destination.name).must_equal(23)
      end
    end
  end

  describe "Batch copy test" do
    before(:each) do
      @batch_origin = table_create(:batch_origin)
      @batch_destination = table_create(:batch_destination)
      @batch_migration = Lhm::Migration.new(@batch_origin, @batch_destination)
    end

    it "should copy 100 rows from batch_origin to batch_destination" do
      100.times { |n| execute("insert into batch_origin set id = '#{ n * n + 100 }'") }

      Lhm::Chunker.new(@batch_migration, connection, { :stride => 40, :batch_mode => true }).run

      slave do
        count_all(@batch_destination.name).must_equal(100)
      end
    end
  end
end
