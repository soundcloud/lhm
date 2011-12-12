#
#  copyright (c) 2011, soundcloud ltd., rany keddo, tobias bielohlawek, tobias
#  schmidt
#

require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'

def xit(*args); end

describe LargeHadronMigrator::Entangler do
  include UnitHelper

  before(:each) do
    @origin = LargeHadronMigrator::Table.new("origin")
    @destination = LargeHadronMigrator::Table.new("destination")
    @tangle = LargeHadronMigrator::Entangler.new(@origin, @destination)
  end

  describe "activation" do
    before(:each) do
      cols = {
        "info" => { :type => "varchar(255)" },
        "tags" => { :type => "varchar(255)" }
      }

      @origin.columns = cols
      @destination.columns = cols
    end

    it "should create insert trigger to destination table" do
      ddl = %Q{
        create trigger `lhmt_ins_origin`
        after insert on `origin` for each row
        replace into `destination` info, tags
        values `NEW.info`, `NEW.tags`
      }

      @tangle.entangle.must_include strip(ddl)
    end

    it "should create an update trigger to the destination table" do
      ddl = %Q{
        create trigger `lhmt_upd_origin`
        after update on `origin` for each row
        replace into `destination` info, tags
        values `NEW.info`, `NEW.tags`
      }

      @tangle.entangle.must_include strip(ddl)
    end

    it "should create a delete trigger to the destination table" do
      ddl = %Q{
        create trigger `lhmt_del_origin`
        after delete on `origin` for each row
        delete ignore from `destination`
        where `destination`.`id` = OLD.`id`
      }

      @tangle.entangle.must_include strip(ddl)
    end
  end

  describe "removal" do
    it "should remove insert trigger" do
      @tangle.untangle.must_include "drop trigger if exists `lhmt_ins_origin`"
    end

    it "should remove update trigger" do
      @tangle.untangle.must_include "drop trigger if exists `lhmt_upd_origin`"
    end

    it "should remove delete trigger" do
      @tangle.untangle.must_include "drop trigger if exists `lhmt_del_origin`"
    end
  end

  def strip(sql)
    sql.strip.gsub(/\n */, "\n")
  end
end

