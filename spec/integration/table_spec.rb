# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require File.expand_path(File.dirname(__FILE__)) + '/integration_helper'
require 'lhm/table'

describe Lhm::Table do
  include IntegrationHelper

  describe Lhm::Table::Parser do
    describe "create table parsing" do
      before(:each) do
        connect_master!
        @table = table_create(:users)
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

      it "should parse constraints" do
        begin
          @table = table_create(:fk_example)
          @table.constraints.keys.must_equal %w{user_id}

          expected = {
            name: "fk_example_ibfk_1",
            referenced_table: "users",
            referenced_column: "id"
          }

          hash_slice(@table.constraints['user_id'], expected.keys).must_equal expected
        ensure
          execute 'drop table if exists fk_example'
        end
      end
    end
  end
end
