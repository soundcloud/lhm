#
#  copyright (c) 2011, soundcloud ltd., rany keddo, tobias bielohlawek, tobias
#  schmidt
#

require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'

describe LargeHadronMigrator::Chunker do
  include UnitHelper

  describe "chunk iterator" do
    it "should return one partially filled chunk"
    it "should return one fully filled chunk"
    it "should return a full and a partial chunk"
    it "should return one partially filled chunk starting from minimum id"
    it "should start chunking at table.lowest_id"
  end
end
