# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'

require 'lhm/table'
require 'lhm/migration'
require 'lhm/atomic_switcher'

describe Lhm::AtomicSwitcher do
  include UnitHelper

  before(:each) do
    @start       = Time.now
    @origin      = Lhm::Table.new('origin')
    @destination = Lhm::Table.new('destination')
    @migration   = Lhm::Migration.new(@origin, @destination, @start)
    @switcher    = Lhm::AtomicSwitcher.new(@migration, nil)
  end

  describe 'atomic switch' do
    it 'should perform a single atomic rename' do
      @switcher.
        statements.
        must_equal([
          "rename table `origin` to `#{ @migration.archive_name }`, " \
          '`destination` to `origin`'
        ])
    end
  end
end
