# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require File.expand_path(File.dirname(__FILE__)) + '/integration_helper'
require 'lhm/table'
require 'lhm/migration'

describe Lhm::Chunker do
  include IntegrationHelper

  before(:each) { connect_master! }

  describe 'copying' do
    before(:each) do
      @origin = table_create(:origin)
      @destination = table_create(:destination)
      @migration = Lhm::Migration.new(@origin, @destination)
    end

    it 'should copy 23 rows from origin to destination with time based throttler' do
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

    it 'should copy 23 rows from origin to destination with slave lag based throttler' do
      23.times { |n| execute("insert into origin set id = '#{ n * n + 23 }'") }

      printer = MiniTest::Mock.new
      5.times { printer.expect(:notify, :return_value, [Fixnum, Fixnum]) }
      printer.expect(:end, :return_value, [])

      Lhm::Chunker.new(
        @migration, connection, { :throttler => Lhm::Throttler::SlaveLag.new(:stride => 100, :connection => connection), :printer => printer }
      ).run

      slave do
        count_all(@destination.name).must_equal(23)
      end

      printer.verify
    end

    it 'should throttle work stride based on slave lag' do
      5.times { |n| execute("insert into origin set id = '#{ (n * n) + 1 }'") }

      printer = MiniTest::Mock.new
      15.times { printer.expect(:notify, :return_value, [Fixnum, Fixnum]) }
      printer.expect(:end, :return_value, [])

      throttler = Lhm::Throttler::SlaveLag.new(:stride => 10, :allowed_lag => 0, :connection => connection)
      def throttler.max_current_slave_lag
        1
      end 
      
      Lhm::Chunker.new(
        @migration, connection, { :throttler => throttler, :printer => printer }
      ).run

      assert_equal(Lhm::Throttler::SlaveLag::DEFAULT_TIMEOUT * 2 * 2, throttler.timeout_seconds)      

      slave do
        count_all(@destination.name).must_equal(5)
      end

      printer.verify
    end

    it 'should detect a single slave with no lag in the default configuration' do
      5.times { |n| execute("insert into origin set id = '#{ (n * n) + 1 }'") }

      printer = MiniTest::Mock.new
      15.times { printer.expect(:notify, :return_value, [Fixnum, Fixnum]) }
      printer.expect(:end, :return_value, [])

      throttler = Lhm::Throttler::SlaveLag.new(:stride => 10, :allowed_lag => 0, :connection => connection)
      slaves = throttler.send(:get_slaves).map { |slave_host| slave_host.partition(":")[0] }
      assert_equal(["localhost"], slaves)

      def throttler.slave_hosts
        ["127.0.0.1"]
      end

      ActiveRecord::Base.connection_config[:port] = "3307"

      Lhm::Chunker.new(
        @migration, connection, { :throttler => throttler, :printer => printer }
      ).run

      assert_equal(Lhm::Throttler::SlaveLag::DEFAULT_TIMEOUT, throttler.timeout_seconds)      
      assert_equal(0, throttler.send(:max_current_slave_lag))      

      slave do
        count_all(@destination.name).must_equal(5)
      end

      printer.verify
    end
  end
end
