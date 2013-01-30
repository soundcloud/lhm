# Copyright (c) 2011, SoundCloud Ltd.

require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'
require 'lhm/connection'

if defined?(DataMapper)
  describe Lhm::Connection::DataMapperConnection do
    let(:data_mapper) { MiniTest::Mock.new }
    let(:options)     { { 'database' => 'the db' } }

    before do
      data_mapper.expect :is_a?, true, [DataMapper::Adapters::AbstractAdapter]
      data_mapper.expect :options, options
    end

    after do
      data_mapper.verify
    end

    it 'creates a DataMapperConnection when the adapter is from DM' do
      connection.must_be_instance_of(Lhm::Connection::DataMapperConnection)
    end

    it 'initializes the db name from the database option' do
      connection.current_database.must_equal('the db')
    end

    it 'initializes the db name form the path if the database option is not available' do
      options['database'] = nil
      options['path'] = '/still the db'

      connection.current_database.must_equal('still the db')
    end

    it 'backticks the table names' do
      table_name = 'my_table'

      data_mapper.expect :select,
        [{ :sql => 'returned sql' }],
        ["show create table `#{table_name}`"]

      connection.show_create(table_name)
    end

    def connection
      Lhm::Connection.new(data_mapper)
    end
  end
end
