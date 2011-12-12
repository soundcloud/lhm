#
#  copyright (c) 2011, soundcloud ltd., rany keddo, tobias bielohlawek, tobias
#  schmidt
#

require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'

describe LargeHadronMigrator::Chunker do
  include UnitHelper

  before(:each) do
    @table = LargeHadronMigrator::Table.new("chunking")
  end

  describe "one" do
    it "should have one chunk" do
      chunker(@table).traversable_chunks_up_to(100).must_equal 1
    end

    it "should lower bound chunk on 1" do
      chunker(@table).bottom(chunk = 1).must_equal 1
    end

    it "should upper bound chunk on 100" do
      chunker(@table).top(chunk = 1, limit = 100).must_equal 100
    end
  end

  describe "two" do
    it "should have two chunks" do
      chunker(@table).traversable_chunks_up_to(150_000).must_equal 2
    end

    it "should lower bound second chunk on 100_000" do
      chunker(@table).bottom(chunk = 2).must_equal 100_001
    end

    it "should upper bound second chunk on 150_000" do
      chunker(@table).top(chunk = 2, limit = 150_000).must_equal 150_000
    end
  end

  describe "iterating" do
    it "should iterate" do
      chunker(@table, stride = 150).up_to(limit = 100) do |bottom, top|
        bottom.must_equal 1
        top.must_equal 100
      end
    end
  end

  def chunker(table, stride = 100_000, throttle = 0)
    LargeHadronMigrator::Chunker.new(table, stride, throttle)
  end
end

