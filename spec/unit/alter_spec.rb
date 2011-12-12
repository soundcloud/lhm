#
#  copyright (c) 2011, soundcloud ltd., rany keddo, tobias bielohlawek, tobias
#  schmidt
#

require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'

def xit(*args); end

describe LargeHadronMigrator::Alter do
  include UnitHelper

  describe "index changes" do
    before(:each) do
      @table = LargeHadronMigrator::Table.new("altering")
      @alter = LargeHadronMigrator::Alter.new(@table)
    end

    it "should name index with a single column" do
      @alter
        .idx_name(["name"])
        .must_equal("name_index")
    end

    it "should name index with a multiple columns" do
      @alter
        .idx_name(["name", "firstname"])
        .must_equal("name_and_firstname_index")
    end

    it "should add an index" do
      @alter.add_index(["a", "b"])

      @alter.changes.must_equal [
        "create index `a_and_b_index` on altering(a, b)"
      ]
    end

    it "should remove an index" do
      @alter.remove_index ["b", "a"]

      @alter.changes.must_equal [
        "drop index `b_and_a_index` on `altering`"
      ]
    end
  end

  describe "column changes" do
    before(:each) do
      @table = LargeHadronMigrator::Table.new("altering")
      @alter = LargeHadronMigrator::Alter.new(@table)
    end

    it "should add a column" do
      @alter.add_column "logins", "INT(12)"

      @alter.changes.must_equal [
        "alter table `altering` add column `logins` INT(12)"
      ]
    end

    it "should remove a column" do
      @alter.remove_column "logins"

      @alter.changes.must_equal [
        "alter table `altering` drop `logins`"
      ]
    end
  end

  describe "direct changes" do
    before(:each) do
      @table = LargeHadronMigrator::Table.new("altering")
      @alter = LargeHadronMigrator::Alter.new(@table)
    end

    it "should accept a ddl statement" do
     ddl = @alter.ddl "alter table `%s` add column `f` tinyint(1)" % @alter.name

     @alter.changes.must_equal [
      "alter table `altering` add column `f` tinyint(1)"
    ]
    end

  end

  describe "multiple changes" do
    before(:each) do
      @table = LargeHadronMigrator::Table.new("altering")
      @alter = LargeHadronMigrator::Alter.new(@table)
    end

    it "should add two columns" do
      @alter.add_column "first", "VARCHAR(64)"
      @alter.add_column "last", "VARCHAR(64)"
      @alter.changes.length.must_equal 2

      @alter
        .changes[0]
        .must_equal "alter table `altering` add column `first` VARCHAR(64)"

      @alter
        .changes[1]
        .must_equal "alter table `altering` add column `last` VARCHAR(64)"
    end
  end
end

