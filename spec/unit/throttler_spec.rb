require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'

require 'lhm/throttler'

describe Lhm::Throttler do
  include UnitHelper

  before :each do
    @mock = Class.new do
      extend Lhm::Throttler
    end

    @conn = Class.new do
      def execute
      end
    end
  end

  describe '#setup_throttler' do
    describe 'when passing a time_throttler key' do
      before do
        @mock.setup_throttler(:time_throttler, delay: 2)
      end

      it 'instantiates the time throttle' do
        @mock.throttler.class.must_equal Lhm::Throttler::Time
      end

      it 'returns 2 seconds as time' do
        @mock.throttler.timeout_seconds.must_equal 2
      end
    end

    describe 'when passing a slave_lag_throttler key' do
      before do
        @mock.setup_throttler(:slave_lag_throttler, allowed_lag: 20)
      end

      it 'instantiates the slave_lag throttle' do
        @mock.throttler.class.must_equal Lhm::Throttler::SlaveLag
      end

      it 'returns 20 seconds as allowed_lag' do
        @mock.throttler.allowed_lag.must_equal 20
      end
    end

    describe 'when passing a time_throttler instance' do

      before do
        @instance = Class.new(Lhm::Throttler::Time) do
          def timeout_seconds
            0
          end
        end.new

        @mock.setup_throttler(@instance)
      end

      it 'returns the instace given' do
        @mock.throttler.must_equal @instance
      end

      it 'returns 0 seconds as time' do
        @mock.throttler.timeout_seconds.must_equal 0
      end
    end

    describe 'when passing a slave_lag_throttler instance' do

      before do
        @instance = Lhm::Throttler::SlaveLag.new
        def @instance.timeout_seconds
          0
        end

        @mock.setup_throttler(@instance)
      end

      it 'returns the instace given' do
        @mock.throttler.must_equal @instance
      end

      it 'returns 0 seconds as time' do
        @mock.throttler.timeout_seconds.must_equal 0
      end
    end

    describe 'when passing a time_throttler class' do

      before do
        @klass = Class.new(Lhm::Throttler::Time)
        @mock.setup_throttler(@klass)
      end

      it 'has the same class as given' do
        @mock.throttler.class.must_equal @klass
      end
    end

    describe 'when passing a slave_lag_throttler class' do

      before do
        @klass = Class.new(Lhm::Throttler::SlaveLag)
        @mock.setup_throttler(@klass)
      end

      it 'has the same class as given' do
        @mock.throttler.class.must_equal @klass
      end
    end
  end

  describe '#throttler' do

    it 'returns the default Time based' do
      @mock.throttler.class.must_equal Lhm::Throttler::Time
    end

    it 'should default to 100 milliseconds' do
      @mock.throttler.timeout_seconds.must_equal 0.1
    end
  end
end
