require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'

require 'lhm/throttle'

describe Lhm::Throttle do
  include UnitHelper

  before :each do
    @mock = Class.new do
      extend Lhm::Throttle
    end
  end

  describe "#setup_throttle" do

    describe "when passing 100 milliseconds" do

      before do
        @mock.setup_throttle(100)
      end

      it "instantiates a legacy throttle" do
        @mock.throttle.class.must_equal Lhm::Throttle::LegacyTime
      end

      it "returns in seconds" do
        @mock.throttle.throttle_seconds.must_equal 0.1
      end
    end

    describe "when passing a key" do

      before do
        @mock.setup_throttle(:time_throttle, :delay => 2)
      end

      it "instantiates the time throttle" do
        @mock.throttle.class.must_equal Lhm::Throttle::Time
      end

      it "returns 2 seconds as time" do
        @mock.throttle.throttle_seconds.must_equal 2
      end
    end

    describe "when passing an instance" do

      before do
        @instance = Class.new(Lhm::Throttle::Time) do
          def throttle_seconds
            0
          end
        end.new

        @mock.setup_throttle(@instance)
      end

      it "returns the instace given" do
        @mock.throttle.must_equal @instance
      end

      it "returns 0 seconds as time" do
        @mock.throttle.throttle_seconds.must_equal 0
      end
    end

    describe "when passing a class" do

      before do
        @klass = Class.new(Lhm::Throttle::Time)
        @mock.setup_throttle(@klass)
      end

      it "has the same class as given" do
        @mock.throttle.class.must_equal @klass
      end
    end
  end

  describe "#throttle" do

    it "returns the default Time based" do
      @mock.throttle.class.must_equal Lhm::Throttle::Time
    end

    it "should default to 100 milliseconds" do
      @mock.throttle.throttle_seconds.must_equal 0.1
    end
  end
end
