# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require File.expand_path(File.dirname(__FILE__)) + '/integration_helper'

require 'lhm'

describe Lhm do
  include IntegrationHelper


    describe 'the simplest case' do
      before(:each) do
        connect_master!
        Lhm.cleanup(true)
        %w(fk_child_table origin_example).each do |table|
          execute "drop table if exists #{table}"
        end
        %w(origin_example fk_child_table).each do |table|
          execute "drop table if exists `fk_child_table`"
          table_create(table)
      end
    end

    after(:each) do
      Lhm.cleanup(true)
    end

    it 'should show the foreign key constraints for given table' do
      actual = table_read(:origin_example).references
      expected = [{
        "constraint_name"=> "fk_origin_table_id",
        "table_name"=> "fk_child_table",
        "table_schema"=> "lhm",
        "column_name"=> "origin_table_id"
        }]
      actual.must_equal(expected)
    end

    it 'should raise an exception for foreign key constraint fails for referencing tables' do
      exception = assert_raises(Exception) {
        Lhm.change_table(:origin_example) do |t|
          t.add_column(:new_column, "INT(12) DEFAULT '0'")
        end
      }
      references = table_read(:origin_example).references
      tables = references.map{|a| "#{a['table_name']}:#{a['constraint_name']}"}.join(', ')
      message = "foreign key constraint fails for tables (#{tables}); before running LHM migration you need to drop this foreign keys;"
      assert_equal(message, exception.message )
    end

    it 'should add a column after droping foreign key constraints' do
      execute "alter table `fk_child_table` drop foreign key `fk_origin_table_id`"
      Lhm.change_table(:origin_example) do |t|
        t.add_column(:new_column, "INT(12) DEFAULT '0'")
      end
      connect_master!
      table_read(:origin_example).columns['new_column'].must_equal({
        :type => 'int(12)',
        :is_nullable => 'YES',
        :column_default => '0',
      })
    end
  end
end
