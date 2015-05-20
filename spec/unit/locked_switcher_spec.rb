# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'

require 'lhm/table'
require 'lhm/migration'
require 'lhm/locked_switcher'

describe Lhm::LockedSwitcher do
  include UnitHelper

  before(:each) do
    @start       = Time.now
    @origin      = Lhm::Table.new('origin')
    @destination = Lhm::Table.new('destination')
    @migration   = Lhm::Migration.new(@origin, @destination, @start)
    @switcher    = Lhm::LockedSwitcher.new(@migration, nil)
  end

  describe 'uncommitted' do
    it 'should disable autocommit first' do
      @switcher.
        statements[0..1].
        must_equal([
          'set @lhm_auto_commit = @@session.autocommit',
          'set session autocommit = 0'
        ])
    end

    it 'should reapply original autocommit settings at the end' do
      @switcher.
        statements[-1].
        must_equal('set session autocommit = @lhm_auto_commit')
    end
  end

  describe 'switch' do
    it 'should lock origin and destination table, switch, commit and unlock' do
      @switcher.
        switch.
        must_equal([
          'lock table `origin` write, `destination` write',
          "alter table `origin` rename `#{ @migration.archive_name }`",
          'alter table `destination` rename `origin`',
          'commit',
          'unlock tables'
        ])
    end
  end
end
