#
#  copyright (c) 2011, soundcloud ltd., rany keddo, tobias bielohlawek, tobias
#  schmidt
#

require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'

describe LargeHadronMigrator::Changes do
  include UnitHelper

  describe "altering" do
    before(:each) do
      @table = LargeHadronMigrator::Table.new("altering")
      @alter = LargeHadronMigrator::Alter.new(@table)
    end

    it "should add a column" do
      @alter.add_column :logins, "INT(12)"

      flunk
    end

    it "should remove a column" do
      @alter.remove_column :logins

      flunk
    end

    it "should add an index" do
      @alter.add_index :logins, :created_at

      flunk
    end

    it "should remove an index" do
      @alter.remove_index :logins, :created_at

      flunk
    end

    it "should accept a ddl statement" do
      @alter.execute "alter table %s add column flag tinyint(1)" % @alter.name

      flunk
    end
  end
end

