# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require File.expand_path(File.dirname(__FILE__)) + '/integration_helper'

require 'lhm/table'
require 'lhm/migration'
require 'lhm/atomic_switcher'

describe Lhm::AtomicSwitcher do
  include IntegrationHelper

  before(:each) { connect_master! }

  describe 'switching' do
    before(:each) do
      Thread.abort_on_exception = true
      @origin      = table_create("origin")
      @destination = table_create("destination")
      @migration   = Lhm::Migration.new(@origin, @destination)
      Lhm.logger = Logger.new('/dev/null')
      @connection.execute("SET GLOBAL innodb_lock_wait_timeout=3")
      @connection.execute("SET GLOBAL lock_wait_timeout=3")
    end

    after(:each) do
      Thread.abort_on_exception = false
    end

   it "should retry on lock wait timeouts" do
     skip "This spec only works with mysql2" unless defined? Mysql2

     without_verbose do
       queue = Queue.new

       locking_thread = start_locking_thread(10, queue, "DELETE from #{@destination.name}")

       switching_thread = Thread.new do
         conn = ar_conn 3306
         switcher = Lhm::AtomicSwitcher.new(@migration, conn)
         switcher.retry_sleep_time = 0.2
         queue.pop
         switcher.run
         Thread.current[:retries] = switcher.retries
       end

       switching_thread.join
       locking_thread.join
       assert switching_thread[:retries] > 0, "The switcher did not retry"
     end
   end

   it "should give up on lock wait timeouts after MAX_RETRIES" do
     skip "This spec only works with mysql2" unless defined? Mysql2

     without_verbose do
       queue = Queue.new
       locking_thread = start_locking_thread(10, queue, "DELETE from #{@destination.name}")

       switching_thread = Thread.new do
         conn = ar_conn 3306

         switcher = Lhm::AtomicSwitcher.new(@migration, conn)
         switcher.max_retries = 2
         switcher.retry_sleep_time = 0
         queue.pop
         begin
           switcher.run
         rescue ActiveRecord::StatementInvalid => error
           Thread.current[:exception] = error
         end
       end

       switching_thread.join
       locking_thread.join
       assert switching_thread[:exception].is_a?(ActiveRecord::StatementInvalid)
     end
   end

    it "should raise on non lock wait timeout exceptions" do
      switcher = Lhm::AtomicSwitcher.new(@migration, connection)
      switcher.send :define_singleton_method, :statements do
        ['SELECT', '*', 'FROM', 'nonexistent']
      end
      ->{ switcher.run }.must_raise(ActiveRecord::StatementInvalid)
    end

    it 'rename origin to archive' do
      switcher = Lhm::AtomicSwitcher.new(@migration, connection)
      switcher.run

      slave do
        table_exists?(@origin).must_equal true
        table_read(@migration.archive_name).columns.keys.must_include 'origin'
      end
    end

    it 'rename destination to origin' do
      switcher = Lhm::AtomicSwitcher.new(@migration, connection)
      switcher.run

      slave do
        table_exists?(@destination).must_equal false
        table_read(@origin.name).columns.keys.must_include 'destination'
      end
    end
  end
end
