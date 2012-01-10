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
      @table.destination_name.must_equal "lhmd_users"
    end

    it "should name index with a single column" do
      @table.
        idx_name(["name"]).
        must_equal("index_users_on_name")
    end

    it "should name index with a multiple columns" do
      @table.
        idx_name(["name", "firstname"]).
        must_equal("index_users_on_name_and_firstname")
    end
  end

  describe "constraints" do
    before(:each) do
      @table = Lhm::Table::Parser.new(fixture("users.ddl")).parse
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

  describe Lhm::Table::Parser do
    describe "create table parsing" do
      before(:each) do
        @table = Lhm::Table::Parser.new(fixture("users.ddl")).parse
      end

      it "should parse table name in show create table" do
        @table.name.must_equal("users")
      end

      it "should parse table options in show create table" do
        @table.table_options.must_equal("ENGINE=InnoDB DEFAULT CHARSET=utf8")
      end

      it "should parse primary key" do
        @table.primary_key.must_equal("id")
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

