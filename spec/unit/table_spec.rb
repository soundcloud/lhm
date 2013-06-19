# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'

require 'lhm/table'

describe Lhm::Table do
  include UnitHelper

  describe "names" do
    it "should name destination" do
      @table = Lhm::Table.new("users")
      @table.destination_name.must_equal "lhmn_users"
    end
  end

  describe 'ddl' do
    it "should build the destination table" do
      table = "users"
      schema = "default"

      @table = Lhm::Table.new(table, schema, "id", %Q{CREATE TABLE `#{table}` (random_constraint)})
      @table.constraints['user_id'] = {:name => 'random_constraint', :referenced_column => true}
      Lhm::Table.schema_constraints(schema, {'random_constraint_1' => true})

      @table.destination_ddl.must_equal %Q{CREATE TABLE `#{@table.destination_name}` (random_constraint_2)}
    end
  end

  describe "constraints" do
    it "should be satisfied with a single column primary key called id" do
      @table = Lhm::Table.new("table", "default", "id")
      @table.satisfies_primary_key?.must_equal true
    end

    it "should not be satisfied with a primary key unless called id" do
      @table = Lhm::Table.new("table", "default", "uuid")
      @table.satisfies_primary_key?.must_equal false
    end

    it "should not be satisfied with multicolumn primary key" do
      @table = Lhm::Table.new("table", "default", ["id", "secondary"])
      @table.satisfies_primary_key?.must_equal false
    end
  end
end
