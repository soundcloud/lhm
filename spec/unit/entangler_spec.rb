# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'

require 'lhm/table'
require 'lhm/migration'
require 'lhm/entangler'

describe Lhm::Entangler do
  include UnitHelper

  before(:each) do
    @origin = Lhm::Table.new('origin')
    @destination = Lhm::Table.new('destination')
    @migration = Lhm::Migration.new(@origin, @destination)
    @entangler = Lhm::Entangler.new(@migration)
  end

  let(:insert_ddl) {
    %Q{
        create trigger `lhmt_ins_origin`
        after insert on `origin` for each row
        replace into `destination` (`info`, `tags`) /* large hadron migration */
        values (`NEW`.`info`, `NEW`.`tags`)
      }
  }

  let(:update_ddl) {
    %Q{
      create trigger `lhmt_upd_origin`
      after update on `origin` for each row
      replace into `destination` (`info`, `tags`) /* large hadron migration */
      values (`NEW`.`info`, `NEW`.`tags`)
    }
  }

  let(:delete_ddl) {
    %Q{
      create trigger `lhmt_del_origin`
      after delete on `origin` for each row
      delete ignore from `destination` /* large hadron migration */
      where `destination`.`id` = OLD.`id`
    }
  }

  describe 'activation' do
    before(:each) do
      @origin.columns['info'] = { :type => 'varchar(255)' }
      @origin.columns['tags'] = { :type => 'varchar(255)' }

      @destination.columns['info'] = { :type => 'varchar(255)' }
      @destination.columns['tags'] = { :type => 'varchar(255)' }
    end

    it 'should create insert trigger to destination table' do
      @entangler.entangle.must_include strip(insert_ddl)
    end

    it 'should create an update trigger to the destination table' do
      @entangler.entangle.must_include strip(update_ddl)
    end

    it 'should create a delete trigger to the destination table' do
      @entangler.entangle.must_include strip(delete_ddl)
    end
  end

  describe 'removal' do
    it 'should remove insert trigger' do
      @entangler.untangle.must_include('drop trigger if exists `lhmt_ins_origin`')
    end

    it 'should remove update trigger' do
      @entangler.untangle.must_include('drop trigger if exists `lhmt_upd_origin`')
    end

    it 'should remove delete trigger' do
      @entangler.untangle.must_include('drop trigger if exists `lhmt_del_origin`')
    end
  end

  describe 'selective entangle' do
    before(:each) do
      @entangler = Lhm::Entangler.new(@migration, nil, :triggers => [:update])

      @origin.columns['info'] = { :type => 'varchar(255)' }
      @origin.columns['tags'] = { :type => 'varchar(255)' }

      @destination.columns['info'] = { :type => 'varchar(255)' }
      @destination.columns['tags'] = { :type => 'varchar(255)' }
    end

    it 'should create update trigger to destination table' do
      @entangler.entangle.must_include strip(update_ddl)
    end

    it 'should not create insert trigger to destination table' do
      @entangler.entangle.wont_include strip(insert_ddl)
    end

    it 'should not create delete trigger to destination table' do
      @entangler.entangle.wont_include strip(delete_ddl)
    end

    it 'should remove update trigger' do
      @entangler.untangle.must_include('drop trigger if exists `lhmt_upd_origin`')
    end

    it 'should not remove insert trigger' do
      @entangler.untangle.wont_include('drop trigger if exists `lhmt_ins_origin`')
    end

    it 'should not remove delete trigger' do
      @entangler.untangle.wont_include('drop trigger if exists `lhmt_del_origin`')
    end
  end

end
