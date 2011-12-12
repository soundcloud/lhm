#
#  copyright (c) 2011, soundcloud ltd., rany keddo, tobias bielohlawek, tobias
#  schmidt
#

require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'

describe LargeHadronMigrator::LockedSwitcher do
  include UnitHelper

  before(:each) do
    @origin = "test"
    @destination = "lhmd-test"
    @archive = "lhma-test"
    @switcher = LargeHadronMigrator::LockedSwitcher.new(@origin, @destination, @archive)
  end

  describe "switch" do
    it "should disable autocommit first" do
      @switcher.switch.first.must_equal "set session autocommit=0"
    end

    it "should lock origin and destination table" do
      @switcher.switch.must_include "lock table `test` write, `lhmd-test` write"
    end

    it "should rename origin to archive" do
      @switcher.switch.must_include "alter table `test` rename `lhma-test`"
    end

    it "should rename destination to origin" do
      @switcher.switch.must_include "alter table `lhmd-test` rename `test`"
    end

    it "should commit the changes and release the locks" do
      @switcher.switch.must_include "commit"
      @switcher.switch.must_include "unlock tables"
    end

    it "should enable autocommit again" do
      @switcher.switch.last.must_equal "set session autocommit=1"
    end
  end
end
