# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require File.expand_path(File.dirname(__FILE__)) + '/integration_helper'

require 'lhm/table'
require 'lhm/migration'
require 'lhm/entangler'

describe Lhm::Entangler do
  include IntegrationHelper

  before(:each) { connect_master!(pool_num: 100) }

  describe 'entanglement' do
    before(:each) do
      @origin = table_create('origin')
      @destination = table_create('destination')
      @migration = Lhm::Migration.new(@origin, @destination)
      @entangler = Lhm::Entangler.new(@migration, connection)
    end

    it 'should replay inserts from origin into destination' do
      @entangler.run do
        execute("insert into origin (common) values ('inserted')")
      end

      slave do
        count(:destination, 'common', 'inserted').must_equal(1)
      end
    end

    it 'should replay deletes from origin into destination' do
      execute("insert into origin (common) values ('inserted')")

      @entangler.run do
        execute("delete from origin where common = 'inserted'")
      end

      slave do
        count(:destination, 'common', 'inserted').must_equal(0)
      end
    end

    it 'should replay updates from origin into destination' do
      @entangler.run do
        execute("insert into origin (common) values ('inserted')")
        execute("update origin set common = 'updated'")
      end

      slave do
        count(:destination, 'common', 'updated').must_equal(1)
      end
    end

    it 'should remove entanglement' do
      @entangler.run {}

      execute("insert into origin (common) values ('inserted')")

      slave do
        count(:destination, 'common', 'inserted').must_equal(0)
      end
    end

    describe 'when the migration is triggered to resume a previous migration that was aborted in the middle' do
      before do
        ENV['LHM_RESUME_AT'] = '5'
      end

      after do
        ENV.delete('LHM_RESUME_AT')
      end

      it 'does not create triggers in the origin table because they should have been created in the previous run' do
        @entangler.run do
          trigger_count = execute("select count(*) from information_schema.triggers where event_object_table = 'origin'").to_a.flatten.first
          assert_equal trigger_count, 0
        end
      end
    end

    describe 'entanglement with bombarding long running queries on specific tables' do
      before(:each) do
        Lhm::Entangler.const_set('TABLES_WITH_LONG_QUERIES_OLD', Lhm::Entangler::TABLES_WITH_LONG_QUERIES)
        Lhm::Entangler.const_set('TABLES_WITH_LONG_QUERIES', 'origin')
        execute("insert into origin (common) values ('inserted')")
        Lhm::Entangler.const_set('LONG_QUERY_TIME_THRESHOLD_OLD', Lhm::Entangler::LONG_QUERY_TIME_THRESHOLD)
        Lhm::Entangler.const_set('LONG_QUERY_TIME_THRESHOLD', 3)
      end

      after(:each) do
        Lhm::Entangler.const_set('TABLES_WITH_LONG_QUERIES', Lhm::Entangler::TABLES_WITH_LONG_QUERIES_OLD)
        Lhm::Entangler.const_set('TABLES_WITH_LONG_QUERIES_OLD', nil)
        Lhm::Entangler.const_set('LONG_QUERY_TIME_THRESHOLD', Lhm::Entangler::LONG_QUERY_TIME_THRESHOLD)
        Lhm::Entangler.const_set('LONG_QUERY_TIME_THRESHOLD_OLD', nil)
      end

      def long_running_query
        "select sleep(1000) from `origin`"
      end

      describe 'with long running query killing env var enabled' do
        before do
          ENV['LHM_KILL_LONG_RUNNING_QUERIES'] = 'true'
        end

        after do
          ENV.delete('LHM_KILL_LONG_RUNNING_QUERIES')
        end

        it 'kills long running queries involving the origin table and does not block trigger related actions' do
          begin
            threads = []

            puts "spawning threads to spam queries..."
            query_spawning_thread = Thread.new do
              loop do
                sleep(Random.rand(1.5))
                trd = Thread.new do
                  connection = ActiveRecord::Base.connection
                  connection.execute(long_running_query)
                end
                threads << trd
              end
            end
            threads << query_spawning_thread

            puts "attempting trigger actions with bombarding queries..."
            @entangler.run do
              trigger_count = execute("select count(*) from information_schema.triggers where event_object_table = 'origin'").to_a.flatten.first
              assert_equal trigger_count, 3
            end

            trigger_count = execute("select count(*) from information_schema.triggers where event_object_table = 'origin'").to_a.flatten.first
            assert_equal trigger_count, 0
          ensure
            query_spawning_thread.terminate
            puts "stopping query spamming..."
            sleep(3)

            puts "cleaning up rogue long queries..."
            ActiveRecord::Base.connection.reconnect!
            ids = ActiveRecord::Base.connection.execute("select id from information_schema.processlist where info = '#{long_running_query}'").to_a.flatten
            ids.each do |id|
              execute("KILL #{id};")
            end

            puts 'cleaning up threads...'
            threads.each do |trd|
              begin
                trd.join
              rescue => e
                raise e unless e.message =~ /Lost connection to MySQL server/
              end
            end
          end
        end
      end

      describe 'without long running query killing env var enabled' do
        before do
          ENV.delete('LHM_KILL_LONG_RUNNING_QUERIES')
        end

        it 'does not kill long running queries involving the origin table' do
          begin
            threads = []

            puts "spawning threads to spam queries..."
            query_spawning_thread = Thread.new do
              loop do
                sleep(Random.rand(1.5))
                trd = Thread.new do
                  connection = ActiveRecord::Base.connection
                  connection.execute(long_running_query)
                end
                threads << trd
              end
            end
            threads << query_spawning_thread

            sleep(2)

            puts 'attempting trigger actions with bombarding queries'
            err = assert_raises Lhm::Error do
              @entangler.run {}
            end
            assert_match /Lock wait timeout exceeded/ , err.message
          ensure
            query_spawning_thread.terminate
            puts "stopping query spamming..."
            sleep(3)

            puts "cleaning up rogue long queries..."
            ActiveRecord::Base.connection.reconnect!
            ids = ActiveRecord::Base.connection.execute("select id from information_schema.processlist where info = '#{long_running_query}'").to_a.flatten
            ids.each do |id|
              execute("KILL #{id};")
            end

            puts 'cleaning up threads...'
            threads.each do |trd|
              begin
                trd.join
              rescue => e
                raise e unless e.message =~ /Lost connection to MySQL server/
              end
            end
          end
        end
      end
    end
  end
end
