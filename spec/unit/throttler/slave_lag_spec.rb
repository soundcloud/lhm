require File.expand_path(File.dirname(__FILE__)) + '/../unit_helper'

require 'lhm/throttler/slave_lag'

describe Lhm::Throttler::SlaveLag do
  include UnitHelper

  before :each do
    @throttler = Lhm::Throttler::SlaveLag.new
  end

  describe '#throttle_seconds' do
    describe 'with no slave lag' do
      before do
        def @throttler.max_current_slave_lag
          0
        end
      end

      it 'does not alter the currently set timeout' do
        timeout = @throttler.timeout_seconds
        assert_equal(timeout, @throttler.send(:throttle_seconds))
      end
    end

    describe 'with a large slave lag' do
      before do
        def @throttler.max_current_slave_lag
          100
        end
      end

      it 'doubles the currently set timeout' do
        timeout = @throttler.timeout_seconds
        assert_equal(timeout * 2, @throttler.send(:throttle_seconds))
      end

      it 'does not increase the timeout past the maximum' do
        @throttler.timeout_seconds = Lhm::Throttler::SlaveLag::MAX_TIMEOUT
        assert_equal(Lhm::Throttler::SlaveLag::MAX_TIMEOUT, @throttler.send(:throttle_seconds))
      end
    end

    describe 'with no slave lag after it has previously been increased' do
      before do
        def @throttler.max_current_slave_lag
          0
        end
      end

      it 'halves the currently set timeout' do
        @throttler.timeout_seconds *= 2 * 2
        timeout = @throttler.timeout_seconds
        assert_equal(timeout / 2, @throttler.send(:throttle_seconds))
      end

      it 'does not decrease the timeout past the minimum on repeated runs' do
        @throttler.timeout_seconds = Lhm::Throttler::SlaveLag::INITIAL_TIMEOUT * 2
        assert_equal(Lhm::Throttler::SlaveLag::INITIAL_TIMEOUT, @throttler.send(:throttle_seconds))
        assert_equal(Lhm::Throttler::SlaveLag::INITIAL_TIMEOUT, @throttler.send(:throttle_seconds))
      end
    end
  end

  describe '#custom_slave_connection' do
    describe 'with a custom slave connection' do
      before do
        @connection = Object.new # just an object to see if the method returns what we return
        @throttler = Lhm::Throttler::SlaveLag.new(slave_connection: lambda {|host| @connection})
      end

      it 'should use the custom slave connection' do
        assert_equal(@connection, @throttler.send(:slave_connection, "slave.db.local"))
      end
    end
  end

  describe '#slave_hosts' do
    describe 'with no slaves' do
      before do
        def @throttler.get_slaves
          []
        end
      end

      it 'returns no slave hosts' do
        assert_equal([], @throttler.send(:slave_hosts))
      end
    end

    describe 'with only localhost slaves' do
      before do
        def @throttler.get_slaves
          ['localhost:1234', '127.0.0.1:5678']
        end
      end

      it 'returns no slave hosts' do
        assert_equal([], @throttler.send(:slave_hosts))
      end
    end

    describe 'with only remote slaves' do
      before do
        def @throttler.get_slaves
          ['server.example.com:1234', 'anotherserver.example.com']
        end
      end

      it 'returns remote slave hosts' do
        assert_equal(['server.example.com', 'anotherserver.example.com'], @throttler.send(:slave_hosts))
      end
    end
  end
end
