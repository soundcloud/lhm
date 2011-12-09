#
#  copyright (c) 2011, soundcloud ltd., rany keddo, tobias bielohlawek, tobias
#  schmidt
#

require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'

describe LargeHadronMigrator::MysqlTableParser do
  include UnitHelper

  describe "create table parsing" do
    before(:each) do
      ddl = fixture("schema.ddl")
      @table = LargeHadronMigrator::MysqlTableParser.new(ddl).parse
    end

    it "should parse table name in show create table" do
      @table.name.must_equal "users"
    end

    it "should parse table options in show create table" do
      @table.table_options.must_equal "ENGINE=InnoDB DEFAULT CHARSET=utf8"
    end

    it "should parse primary key" do
      @table.primary_key.must_equal "id"
    end

    it "should parse column type in show create table" do
      @table.columns["username"][:type].must_equal "varchar(255)"
    end

    it "should parse column metadata" do
      @table.columns["username"][:metadata].must_equal "DEFAULT NULL"
    end

    it "should parse indices in show create table" do
      @table
        .indices["index_users_on_username_and_created_at"][:metadata]
        .must_equal("(`username`,`created_at`)")
    end

    it "should parse indices in show create table" do
      @table
        .indices["index_users_on_reference"][:metadata]
        .must_equal("(`reference`)")
    end
  end
end
