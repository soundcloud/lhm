# Copyright (c) 2011 - 2013, SoundCloud Ltd.

require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'
require 'lhm/connection'

if defined?(ActiveRecord)
  describe Lhm::Connection::ActiveRecordConnection do
    let(:active_record) { MiniTest::Mock.new }

    before do
      active_record.expect :current_database, 'the db'
    end

    after do
      active_record.verify
    end

    it 'creates an ActiveRecord connection' do
      connection.must_be_instance_of(Lhm::Connection::ActiveRecordConnection)
    end

    it 'initializes the db name from the connection' do
      connection.current_database.must_equal('the db')
    end

    it 'backticks the table names' do
      table_name = 'my_table'

      active_record.expect :execute,
        [['returned sql']],
        ["show create table `#{table_name}`"]

      connection.show_create(table_name)
    end

    def connection
      Lhm::Connection.new(active_record)
    end
  end
end
