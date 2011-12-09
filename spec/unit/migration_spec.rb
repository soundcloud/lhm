#
#  copyright (c) 2011, soundcloud ltd., rany keddo, tobias bielohlawek, tobias
#  schmidt
#

require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'

describe LargeHadronMigrator::Migration do
  include UnitHelper

  it "should name destination" do
    migration = Migration.new(:origin => "origin")
    migration.destination.name.must_equal "lhm_origin"
  end

  it "should name archive" do
    migration = Migration.new(:origin => "origin")
    migration.archive.name.must_equal "lhma_#{ migration.start.to_i }_origin"
  end

  it "should create the table"
  it "should detect if a table exists"
end
