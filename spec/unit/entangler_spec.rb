#
#  copyright (c) 2011, soundcloud ltd., rany keddo, tobias bielohlawek, tobias
#  schmidt
#

require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'

describe LargeHadronMigrator::Entangler do
  include UnitHelper

  before(:each) do
    @origin = LargeHadronMigrator::Table.new("origin")
    @destination = LargeHadronMigrator::Table.new("destination")
    @pipe = LargeHadronMigrator::Entangler.new(@origin, @destination)
  end

  describe "activation" do
    it "should create create trigger to destination table"
    it "should create a delete trigger to the destination table"
    it "should create an update trigger to the destination table"
  end

  describe "removal" do
    it "should remove triggers"
  end
end
