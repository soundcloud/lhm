#
#  Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
#  Schmidt
#

require File.expand_path(File.dirname(__FILE__)) + '/integration_helper'

require 'lhm/table'
require 'lhm/migration'
require 'lhm/entangler'

describe Lhm::Entangler do
  include IntegrationHelper

  before(:each) { connect! }

  describe "entanglement" do
    before(:each) do
      @origin = table_create("origin")
      @destination = table_create("destination")
      @migration = Lhm::Migration.new(@origin, @destination)
      @entangler = Lhm::Entangler.new(@migration, connection)
    end

    it "should replay inserts from origin into destination" do
      @entangler.run do |entangler|
        execute("insert into origin (common) values ('inserted')")
      end

      count(:destination, "common", "inserted").must_equal(1)
    end

    it "should replay deletes from origin into destination" do
      execute("insert into origin (common) values ('inserted')")

      @entangler.run do |entangler|
        execute("delete from origin where common = 'inserted'")
      end

      count(:destination, "common", "inserted").must_equal(0)
    end

    it "should replay updates from origin into destination" do
      @entangler.run do |entangler|
        execute("insert into origin (common) values ('inserted')")
        execute("update origin set common = 'updated'")
      end

      count(:destination, "common", "updated").must_equal(1)
    end

    it "should remove entanglement" do
      @entangler.run {}

      execute("insert into origin (common) values ('inserted')")
      count(:destination, "common", "inserted").must_equal(0)
    end
  end
end

