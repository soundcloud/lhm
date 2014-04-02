# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
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

      printer = MiniTest::Mock.new
      5.times { printer.expect(:notify, :return_value, [Fixnum, Fixnum]) }
      printer.expect(:end, :return_value, [])

      Lhm::Chunker.new(
        @migration, connection, { :throttler => Lhm::Throttler::Time.new(:stride => 100), :printer => printer }
      ).run

      slave do
        count_all(@destination.name).must_equal(23)
      end

     printer.verify
    end
  end
end
