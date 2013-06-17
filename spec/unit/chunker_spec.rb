# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'

require 'lhm/table'
require 'lhm/migration'
require 'lhm/chunker'

describe Lhm::Chunker do
  include UnitHelper

  before(:each) do
    @origin      = Lhm::Table.new("origin")
    @destination = Lhm::Table.new("destination")
    @migration   = Lhm::Migration.new(@origin, @destination)
    @chunker     = Lhm::Chunker.new(@migration, nil, { :start => 1, :limit => 10 })
  end

  describe "copy into" do
    before(:each) do
      @origin.columns["secret"] = { :metadata => "VARCHAR(255)"}
      @destination.columns["secret"] = { :metadata => "VARCHAR(255)"}
    end

    it "should copy the correct range and column" do
      @chunker.copy(from = 1, to = 100).must_equal(
        "insert ignore into `destination` (`secret`) " +
        "select origin.`secret` from `origin` " +
        "where origin.`id` between 1 and 100"
      )
    end
  end

  describe "invalid" do
    before do
      @chunker = Lhm::Chunker.new(@migration, nil, { :start => 0, :limit => -1 })
    end

    it "should not iterate" do
      @chunker.copy_chunks do |bottom, top|
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

    it "should have three chunks" do
      i = 0
      @chunker.copy_chunks {|*| i += 1 }
      i.must_equal 3
    end

    it "should set correct bounds" do
      bounds = []
      @chunker.copy_chunks do |lower, upper|
        bounds << [lower, upper]
      end
      bounds.must_equal [[1, 100_000], [100_001, 200_000], [200_001, 300_000]]
    end
  end

  describe "two" do
    before do
      @chunker = Lhm::Chunker.new(@migration, nil, {
        :stride => 100_000, :start => 2, :limit => 150_000
      })
    end

    it "should have two chunks" do
      i = 0
      @chunker.copy_chunks {|*| i += 1 }
      i.must_equal 2
    end

    it "should set correct bounds" do
      bounds = []
      @chunker.copy_chunks do |lower, upper|
        bounds << [lower, upper]
      end
      bounds.must_equal [[2, 100_001], [100_002, 150_000]]
    end
  end

  describe "iterating" do
    before do
      @chunker = Lhm::Chunker.new(@migration, nil, {
        :stride => 100, :start => 53, :limit => 121
      })
    end

    it "should iterate" do
      @chunker.copy_chunks do |bottom, top|
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
