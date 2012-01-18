#
#  Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
#  Schmidt
#

require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'

require 'lhm/table'

describe Lhm::Table do
  include UnitHelper

  describe "names" do
    before(:each) do
      @table = Lhm::Table::Parser.new(fixture("users.ddl")).parse
    end

    it "should name destination" do
      @table.destination_name.must_equal "lhmn_users"
    end
  end

  describe "constraints" do
    it "should be satisfied with a single column primary key called id" do
      @table = Lhm::Table.new("table", "id")
      @table.satisfies_primary_key?.must_equal true
    end

    it "should not be satisfied with a primary key unless called id" do
      @table = Lhm::Table.new("table", "uuid")
      @table.satisfies_primary_key?.must_equal false
    end

    it "should not be satisfied with multicolumn primary key" do
      @table = Lhm::Table.new("table", ["id", "secondary"])
      @table.satisfies_primary_key?.must_equal false
    end
  end

  describe Lhm::Table::Parser do
    describe "create table parsing" do
      before(:each) do
        @table = Lhm::Table::Parser.new(fixture("users.ddl")).parse
      end

      it "should parse table name in show create table" do
        @table.name.must_equal("users")
      end

      it "should parse primary key" do
        @table.pk.must_equal("id")
      end

      it "should parse column type in show create table" do
        @table.columns["username"][:type].must_equal("varchar(255)")
      end

      it "should parse column metadata" do
        @table.columns["username"][:metadata].must_equal("DEFAULT NULL")
      end

      it "should parse indices in show create table" do
        @table.
          indices["index_users_on_username_and_created_at"][:metadata].
          must_equal("(`username`,`created_at`)")
      end

      it "should parse indices in show create table" do
        @table.
          indices["index_users_on_reference"][:metadata].
          must_equal("(`reference`)")
      end
    end
  end
end

