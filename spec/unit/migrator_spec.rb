# Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'

require 'lhm/table'
require 'lhm/migrator'

describe Lhm::Migrator do
  include UnitHelper

  before(:each) do
    @table = Lhm::Table.new("alt")
    @creator = Lhm::Migrator.new(@table)
  end

  describe "index changes" do
    it "should add an index" do
      @creator.add_index(["a", "b"])

      @creator.statements.must_equal([
        "create index `index_alt_on_a_and_b` on `lhmn_alt` (`a`, `b`)"
      ])
    end

    it "should add an index with prefixed columns" do
      @creator.add_index(["a(10)", "b"])

      @creator.statements.must_equal([
        "create index `index_alt_on_a_and_b` on `lhmn_alt` (`a`(10), `b`)"
      ])
    end

    it "should add an unique index" do
      @creator.add_unique_index(["a(5)", :b])

      @creator.statements.must_equal([
        "create unique index `index_alt_on_a_and_b` on `lhmn_alt` (`a`(5), `b`)"
      ])
    end

    it "should remove an index" do
      @creator.remove_index(["b", "a"])

      @creator.statements.must_equal([
        "drop index `index_alt_on_b_and_a` on `lhmn_alt`"
      ])
    end
  end

  describe "column changes" do
    it "should add a column" do
      @creator.add_column("logins", "INT(12)")

      @creator.statements.must_equal([
        "alter table `lhmn_alt` add column `logins` INT(12)"
      ])
    end

    it "should remove a column" do
      @creator.remove_column("logins")

      @creator.statements.must_equal([
        "alter table `lhmn_alt` drop `logins`"
      ])
    end

    it "should change a column" do
      @creator.change_column("logins", "INT(255)")

      @creator.statements.must_equal([
        "alter table `lhmn_alt` drop `logins`",
        "alter table `lhmn_alt` add column `logins` INT(255)"
      ])
    end
  end

  describe "direct changes" do
    it "should accept a ddl statement" do
     ddl = @creator.ddl("alter table `%s` add column `f` tinyint(1)" % @creator.name)

     @creator.statements.must_equal([
       "alter table `lhmn_alt` add column `f` tinyint(1)"
     ])
    end
  end

  describe "multiple changes" do
    it "should add two columns" do
      @creator.add_column("first", "VARCHAR(64)")
      @creator.add_column("last", "VARCHAR(64)")
      @creator.statements.length.must_equal(2)

      @creator.
        statements[0].
        must_equal("alter table `lhmn_alt` add column `first` VARCHAR(64)")

      @creator.
        statements[1].
        must_equal("alter table `lhmn_alt` add column `last` VARCHAR(64)")
    end
  end
end
