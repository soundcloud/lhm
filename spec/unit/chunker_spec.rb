#
#  Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
#  Schmidt
#

require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'

require 'lhm/table'
require 'lhm/migration'
require 'lhm/entangler'
require 'lhm/chunker'

describe Lhm::Chunker do
  include UnitHelper

  before(:each) do
    @origin      = Lhm::Table.new("origin")
    @destination = Lhm::Table.new("destination")
    @migration   = Lhm::Migration.new(@origin, @destination)
    @entangler   = Lhm::Entangler.new(@migration)
    @chunker     = Lhm::Chunker.new(@migration, @entangler)
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

  describe "one" do
    it "should have one chunk" do
      @chunker.traversable_chunks_up_to(100).must_equal 1
    end

    it "should lower bound chunk on 1" do
      @chunker.bottom(chunk = 1).must_equal 1
    end

    it "should upper bound chunk on 100" do
      @chunker.top(chunk = 1, limit = 100).must_equal 100
    end
  end

  describe "two" do
    it "should have two chunks" do
      @chunker.traversable_chunks_up_to(150_000).must_equal 2
    end

    it "should lower bound second chunk on 100_000" do
      @chunker.bottom(chunk = 2).must_equal 100_001
    end

    it "should upper bound second chunk on 150_000" do
      @chunker.top(chunk = 2, limit = 150_000).must_equal 150_000
    end
  end

  describe "iterating" do
    it "should iterate" do
      @chunker = Lhm::Chunker.new(@migration, nil, nil, {
        :stride => 150,
        :throttle => 0
      })

      @chunker.up_to(limit = 100) do |bottom, top|
        bottom.must_equal 1
        top.must_equal 100
      end
    end
  end
end

