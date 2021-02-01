# Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
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

  describe "constraints" do
    it "should be satisfied with a single column primary key called id" do
      @table = Lhm::Table.new("table", "id")
      @table.satisfies_primary_key?.must_equal true
    end

    it "should not be satisfied with a primary key unless called id" do
      @table = Lhm::Table.new("table", "uuid")
      @table.satisfies_primary_key?.must_equal false
    end
  end
end
