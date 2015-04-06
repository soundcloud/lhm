# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require File.expand_path(File.dirname(__FILE__)) + '/integration_helper'
require 'lhm/table'

describe Lhm::Checkpointer do
  include IntegrationHelper

  before(:each) { connect_master!; Lhm.cleanup }

  let (:checkpoint_table) { Lhm::Table.new('lhm_checkpoint') }

  describe 'checkpointing disabled' do
    before(:each) { Lhm::Checkpointer.new(connection).run {} }

    it 'should do nothing if not enabled' do
      slave do
        table_exists?(checkpoint_table).must_equal(false)
      end
    end
  end

  describe 'checkpointing enabled' do
    before(:each) { @checkpointer = Lhm::Checkpointer.new(connection, :checkpoint => true) }

    it 'should set up the table' do
      @checkpointer.run do
        slave do
          table_exists?(checkpoint_table).must_equal(true)
        end
      end
    end

    it 'should be initialised to 0' do
      @checkpointer.run do
        select_one("select value from #{checkpoint_table.name}")['value'].must_equal(0)
      end
    end

    it 'should be saveable' do
      @checkpointer.run do
        @checkpointer.checkpoint(10)
        select_one("select value from #{checkpoint_table.name}")['value'].must_equal(10)
      end
    end
  end
end
