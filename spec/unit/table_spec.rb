# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'

require 'lhm/table'

describe Lhm::Table do
  include UnitHelper

  describe 'names' do
    it 'should name destination' do
      @table = Lhm::Table.new('users')
      @table.destination_name.must_equal 'lhmn_users'
    end
  end

  describe 'constraints' do
    def set_columns(table, columns)
      table.instance_variable_set('@columns', columns)
    end

    it 'should be satisfied with a single column primary key called id' do
      @table = Lhm::Table.new('table', 'id')
      set_columns(@table, { 'id' => { :type => 'int(1)' } })
      @table.satisfies_id_column_requirement?.must_equal true
    end

    it 'should be satisfied with a primary key not called id, as long as there is still an id' do
      @table = Lhm::Table.new('table', 'uuid')
      set_columns(@table, { 'id' => { :type => 'int(1)' } })
      @table.satisfies_id_column_requirement?.must_equal true
    end

    it 'should not be satisfied if id is not numeric' do
      @table = Lhm::Table.new('table', 'id')
      set_columns(@table, { 'id' => { :type => 'varchar(255)' } })
      @table.satisfies_id_column_requirement?.must_equal false
    end
  end
end
