# Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'

require 'lhm/table'
require 'lhm/migration'
require 'lhm/chunker'

describe Lhm::Chunker do
  include UnitHelper

  before(:each) do
    @origin         = Lhm::Table.new("origin")
    @destination    = Lhm::Table.new("destination")
    @migration      = Lhm::Migration.new(@origin, @destination)
    @chunker        = Lhm::Chunker.new(@migration, nil, { :start => 1, :limit => 10 })
  end

  describe "copy into" do
    before(:each) do
      @origin.columns["secret"] = { :metadata => "VARCHAR(255)"}
      @destination.columns["secret"] = { :metadata => "VARCHAR(255)"}
    end

    it "should copy the correct range and column" do
      @chunker.copy(from = 1, to = 100).must_equal(
        "insert ignore into `destination` (`secret`) " +
        "select `secret` from `origin` " +
        "where `id` between 1 and 100"
      )
    end
  end

  describe "batch copy into" do
    before(:each) do
      @origin.columns["secret"] = { :metadata => "VARCHAR(255)"}
      @destination.columns["secret"] = { :metadata => "VARCHAR(255)"}
    end

    it "should copy the correct range and column" do
      @chunker.copy_batchwise(from = 1, batch = 100).must_equal(
        "insert ignore into `destination` (`secret`) " +
        "select `secret` from `origin` " +
        "where `id` >= #{from} order by id asc limit #{batch}"
      )
    end
  end

  describe "invalid" do
    before do
      @chunker = Lhm::Chunker.new(@migration, nil, { :start => 0, :limit => -1 })
    end

    it "should have zero chunks" do
      @chunker.traversable_chunks_size.must_equal 0
    end

    it "should not iterate" do
      @chunker.up_to do |bottom, top|
        raise "should not iterate"
      end
    end
  end

  describe "one" do
    before do
      @chunker = Lhm::Chunker.new(@migration, nil, {
        :stride => 100_000, :start => 1, :limit => 300_000
      })
    end

    it "should have one chunk" do
      @chunker.traversable_chunks_size.must_equal 3
    end

    it "should lower bound chunk on 1" do
      @chunker.bottom(chunk = 1).must_equal 1
    end

    it "should upper bound chunk on 100" do
      @chunker.top(chunk = 1).must_equal 100_000
    end
  end

  describe "two" do
    before do
      @chunker = Lhm::Chunker.new(@migration, nil, {
        :stride => 100_000, :start => 2, :limit => 150_000
      })
    end

    it "should have two chunks" do
      @chunker.traversable_chunks_size.must_equal 2
    end

    it "should lower bound second chunk on 100_000" do
      @chunker.bottom(chunk = 2).must_equal 100_002
    end

    it "should upper bound second chunk on 150_000" do
      @chunker.top(chunk = 2).must_equal 150_000
    end
  end

  describe "iterating" do
    before do
      @chunker = Lhm::Chunker.new(@migration, nil, {
        :stride => 100, :start => 53, :limit => 121
      })
    end

    it "should iterate" do
      @chunker.up_to do |bottom, top|
        bottom.must_equal 53
        top.must_equal 121
      end
    end
  end

  describe "throttling" do
    it "should default to 100 milliseconds" do
      @chunker.throttle_seconds.must_equal 0.1
    end
  end
end
