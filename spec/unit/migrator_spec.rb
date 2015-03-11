# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'

require 'lhm/table'
require 'lhm/migrator'

describe Lhm::Migrator do
  include UnitHelper

  before(:each) do
    @table = Lhm::Table.new('alt')
    @creator = Lhm::Migrator.new(@table)
  end

  describe 'index changes' do
    it 'should add an index' do
      @creator.add_index(:a)

      @creator.statements.must_equal([
        'create index `index_alt_on_a` on `lhmn_alt` (`a`)'
      ])
    end

    it 'should add a composite index' do
      @creator.add_index([:a, :b])

      @creator.statements.must_equal([
        'create index `index_alt_on_a_and_b` on `lhmn_alt` (`a`, `b`)'
      ])
    end

    it 'should add an index with prefix length' do
      @creator.add_index(['a(10)', 'b'])

      @creator.statements.must_equal([
        'create index `index_alt_on_a_and_b` on `lhmn_alt` (`a`(10), `b`)'
      ])
    end

    it 'should add an index with a custom name' do
      @creator.add_index([:a, :b], :custom_index_name)

      @creator.statements.must_equal([
        'create index `custom_index_name` on `lhmn_alt` (`a`, `b`)'
      ])
    end

    it 'should raise an error when the index name is not a string or symbol' do
      assert_raises ArgumentError do
        @creator.add_index([:a, :b], :name => :custom_index_name)
      end
    end

    it 'should add a unique index' do
      @creator.add_unique_index(['a(5)', :b])

      @creator.statements.must_equal([
        'create unique index `index_alt_on_a_and_b` on `lhmn_alt` (`a`(5), `b`)'
      ])
    end

    it 'should add a unique index with a custom name' do
      @creator.add_unique_index([:a, :b], :custom_index_name)

      @creator.statements.must_equal([
        'create unique index `custom_index_name` on `lhmn_alt` (`a`, `b`)'
      ])
    end

    it 'should raise an error when the unique index name is not a string or symbol' do
      assert_raises ArgumentError do
        @creator.add_unique_index([:a, :b], :name => :custom_index_name)
      end
    end

    it 'should remove an index' do
      @creator.remove_index(['b', 'a'])

      @creator.statements.must_equal([
        'drop index `index_alt_on_b_and_a` on `lhmn_alt`'
      ])
    end

    it 'should remove an index with a custom name' do
      @creator.remove_index([:a, :b], :custom_index_name)

      @creator.statements.must_equal([
        'drop index `custom_index_name` on `lhmn_alt`'
      ])
    end
  end

  describe 'column changes' do
    it 'should add a column' do
      @creator.add_column('logins', 'INT(12)')

      @creator.statements.must_equal([
        'alter table `lhmn_alt` add column `logins` INT(12)'
      ])
    end

    it 'should remove a column' do
      @creator.remove_column('logins')

      @creator.statements.must_equal([
        'alter table `lhmn_alt` drop `logins`'
      ])
    end

    it 'should change a column' do
      @creator.change_column('logins', 'INT(11)')

      @creator.statements.must_equal([
        'alter table `lhmn_alt` modify column `logins` INT(11)'
      ])
    end
  end

  describe 'direct changes' do
    it 'should accept a ddl statement' do
      @creator.ddl('alter table `%s` add column `f` tinyint(1)' % @creator.name)

      @creator.statements.must_equal([
        'alter table `lhmn_alt` add column `f` tinyint(1)'
      ])
    end
  end

  describe 'multiple changes' do
    it 'should add two columns' do
      @creator.add_column('first', 'VARCHAR(64)')
      @creator.add_column('last', 'VARCHAR(64)')
      @creator.statements.length.must_equal(2)

      @creator.
        statements[0].
        must_equal('alter table `lhmn_alt` add column `first` VARCHAR(64)')

      @creator.
        statements[1].
        must_equal('alter table `lhmn_alt` add column `last` VARCHAR(64)')
    end
  end
end
