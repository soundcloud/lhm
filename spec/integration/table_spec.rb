# Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require File.expand_path(File.dirname(__FILE__)) + '/integration_helper'

require 'lhm'
require 'lhm/table'

describe Lhm::Table do
  include IntegrationHelper

  describe Lhm::Table::Parser do
    describe "create table parsing" do
      before(:each) do
        connect_master!
        @table = Lhm::Table::Parser.new(:users, connection).parse
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
        @table.columns["username"][:column_default].must_equal nil
      end

      it "should parse indices" do
        @table.
          indices["index_users_on_username_and_created_at"].
          must_equal(["username", "created_at"])
      end

      it "should parse index" do
        @table.
          indices["index_users_on_reference"].
          must_equal(["reference"])
      end
    end
  end
end
