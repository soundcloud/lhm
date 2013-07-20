# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require File.expand_path(File.dirname(__FILE__)) + '/integration_helper'

require 'lhm'

describe Lhm do
  include IntegrationHelper

  before(:each) { connect_master! }

  before(:each) do
    # Be absolutely sure none of these exist yet
    Lhm.cleanup(true)
    %w{fk_example fk_example_non_sequential}.each do |table|
      execute "drop table if exists #{table}"
    end

    table_create(:users)
  end

  describe 'the simplest case' do
    before(:each) do
      table_create(:fk_example)
    end

    after (:each) do
      # Clean it up since it could cause trouble
      execute 'drop table if exists fk_example'
      Lhm.cleanup(true)
    end
    it 'should handle tables with foriegn keys' do
      Lhm.change_table(:fk_example) do |t|
        t.add_column(:new_column, "INT(12) DEFAULT '0'")
      end

      slave do
        actual = table_read(:fk_example).constraints['user_id']
        expected = {
          name: 'fk_example_ibfk_2',
          referenced_table: 'users',
          referenced_column: 'id'
        }
        hash_slice(actual, expected.keys).must_equal(expected)
      end
    end
  end

  describe 'the foreign key sequence number is not 1' do
    before(:each) do
      table_create(:fk_example_non_sequential)
    end

    it 'should be able to create this table' do
      Lhm.change_table(:fk_example_non_sequential) do |t|
        t.add_column(:new_column, "INT(12) DEFAULT '0'")
      end

      slave do
        actual = table_read(:fk_example_non_sequential).constraints['user_id']
        expected = {
          name: 'fk_example_ibfk_1',
          referenced_table: 'users',
          referenced_column: 'id'
        }
        hash_slice(actual, expected.keys).must_equal(expected)
      end
    end
  end


end
