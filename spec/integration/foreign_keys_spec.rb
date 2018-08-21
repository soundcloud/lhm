# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require File.expand_path(File.dirname(__FILE__)) + '/integration_helper'

require 'lhm'

describe Lhm do
  include IntegrationHelper

  before(:each) do
    connect_master!
    Lhm.cleanup(true)
    %w(fk_example fk_example_second_pass).each do |table|
      execute "drop table if exists #{table}"
    end
    table_create(:users)
  end

  describe 'the simplest case' do
    before(:each) do
      table_create(:fk_example)
    end

    after(:each) do
      execute 'drop table if exists fk_example'
      Lhm.cleanup(true)
    end

    it 'should handle tables with foreign keys by appending the suffix' do
      Lhm.change_table(:fk_example) do |t|
        t.add_column(:new_column, "INT(12) DEFAULT '0'")
      end

      slave do
        actual = table_read(:fk_example).constraints['user_id']
        expected = {
          name: 'fk_example_ibfk_1_lhmn',
          referenced_table: 'users',
          referenced_column: 'id',
        }
        hash_slice(actual, expected.keys).must_equal(expected)

        actual = table_read(:fk_example).constraints['master_id']
        expected = {
          name: 'fk_example_ibfk_2_lhmn',
          referenced_table: 'users',
          referenced_column: 'id',
        }
        hash_slice(actual, expected.keys).must_equal(expected)
      end
    end
  end

  describe 'manage a new migration by removing the suffix' do
    before(:each) do
      table_create(:fk_example_second_pass)
    end

    after(:each) do
      execute 'drop table if exists fk_example_second_pass'
      Lhm.cleanup(true)
    end

    it 'should be able to create this table' do
      Lhm.change_table(:fk_example_second_pass) do |t|
        t.add_column(:new_column, "INT(12) DEFAULT '0'")
      end

      slave do
        actual = table_read(:fk_example_second_pass).constraints['user_id']
        expected = {
          name: 'fk_example_ibfk_1',
          referenced_table: 'users',
          referenced_column: 'id',
        }
        hash_slice(actual, expected.keys).must_equal(expected)

        actual = table_read(:fk_example_second_pass).constraints['master_id']
        expected = {
          name: 'fk_example_ibfk_2',
          referenced_table: 'users',
          referenced_column: 'id',
        }
        hash_slice(actual, expected.keys).must_equal(expected)
      end
    end
  end
end
