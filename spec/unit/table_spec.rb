#
#  copyright (c) 2011, soundcloud ltd., rany keddo, tobias bielohlawek, tobias
#  schmidt
#

require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'

describe LargeHadronMigrator::Table do
  include UnitHelper

  describe "preconditions" do
    before(:each) do
      @table = LargeHadronMigrator::Table.new("constraints")
    end

    it "should be satisfied with a single column primary key called id" do
      @table.primary_key = "id"
      @table.satisfies_primary_key?.must_equal true
    end

    it "should not be satisfied with a primary key unless called id" do
      @table.primary_key = "uuid"
      @table.satisfies_primary_key?.must_equal false
    end

    it "should not be satisfied with multicolumn primary key" do
      @table.primary_key = ["id", "secondary"]
      @table.satisfies_primary_key?.must_equal false
    end
  end

  describe "copy into" do
    it "should copy into the correct destination columns"
    it "should copy from the correct source coloumns"
  end

  describe "altering" do
    before(:each) do
      @table = LargeHadronMigrator::Table.new("altering")
    end

    it "should add a column" do
      @table.add_column :logins, "INT(12)"

      flunk
    end

    it "should remove a column" do
      @table.remove_column :logins

      flunk
    end

    it "should add an index" do
      @table.add_index :logins, :created_at

      flunk
    end

    it "should remove an index" do
      @table.remove_index :logins, :created_at

      flunk
    end

    it "should accept a ddl statement" do
      @table.execute "alter table %s add column flag tinyint(1)" % @table.name

      flunk
    end
  end

  describe "manipulation" do
    it "should clone an existing schema to a new table name"
    it "should rename"
  end

end
