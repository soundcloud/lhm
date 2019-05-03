# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt
require 'test_helper'
require 'yaml'
require 'active_support'
$password = YAML.load_file(File.expand_path(File.dirname(__FILE__)) + '/database.yml')['password'] rescue nil

require 'lhm/table'
require 'lhm/sql_helper'

module IntegrationHelper
  #
  # Connectivity
  #
  def connection
    @connection
  end

  def connect_master!(pool_num: nil)
    connect!(3306, pool_num: pool_num)
  end

  def connect_slave!
    connect!(3307)
  end

  def connect!(port, pool_num: nil)
    adapter = ar_conn(port, pool_num: pool_num)
    Lhm.setup(adapter)
    unless defined?(@@cleaned_up)
      Lhm.cleanup(:run)
      @@cleaned_up  = true
    end
    @connection = adapter
  end

  def ar_conn(port, pool_num: nil)
    ActiveRecord::Base.establish_connection(
      :adapter  => defined?(Mysql2) ? 'mysql2' : 'mysql',
      :host     => '127.0.0.1',
      :database => 'lhm',
      :username => 'root',
      :port     => port,
      :password => $password,
      :pool     => pool_num || 5
    )
    ActiveRecord::Base.connection
  end

  def select_one(*args)
    @connection.select_one(*args)
  end

  def select_value(*args)
    @connection.select_value(*args)
  end

  def select_values(*args)
    @connection.select_values(*args)
  end

  def execute(*args)
    retries = 10
    begin
      @connection.execute(*args)
    rescue => e
      if (retries -= 1) > 0 && e.message =~ /Table '.*?' doesn't exist/
        sleep 0.1
        retry
      else
        raise
      end
    end
  end

  def slave(&block)
    if master_slave_mode?
      connect_slave!

      # need to wait for the slave to catch up. a better method would be to
      # check the master binlog position and wait for the slave to catch up
      # to that position.
      sleep 1
    else
      connect_master!
    end

    yield block

    if master_slave_mode?
      connect_master!
    end
  end

  # Helps testing behaviour when another client locks the db
  def start_locking_thread(lock_for, queue, locking_query)
    Thread.new do
      conn = Mysql2::Client.new(host: '127.0.0.1', database: 'lhm', user: 'root', port: 3306)
      conn.query('BEGIN')
      conn.query(locking_query)
      queue.push(true)
      sleep(lock_for) # Sleep for log so LHM gives up
      conn.query('ROLLBACK')
    end
  end

  #
  # Test Data
  #

  def fixture(name)
    File.read($fixtures.join("#{ name }.ddl"))
  end

  def table_create(fixture_name)
    execute "drop table if exists `#{ fixture_name }`"
    execute fixture(fixture_name)
    table_read(fixture_name)
  end

  def table_rename(from_name, to_name)
    execute "rename table `#{ from_name }` to `#{ to_name }`"
  end

  def table_read(fixture_name)
    Lhm::Table.parse(fixture_name, @connection)
  end

  def table_exists?(table)
    connection.table_exists?(table.name)
  end

  #
  # Database Helpers
  #

  def count(table, column, value)
    query = "select count(*) from #{ table } where #{ column } = '#{ value }'"
    select_value(query).to_i
  end

  def count_all(table)
    query = "select count(*) from `#{ table }`"
    select_value(query).to_i
  end

  def index_on_columns?(table_name, cols, type = :non_unique)
    key_name = Lhm::SqlHelper.idx_name(table_name, cols)

    index?(table_name, key_name, type)
  end

  def index?(table_name, key_name, type = :non_unique)
    non_unique = type == :non_unique ? 1 : 0

    !!select_one(%Q<
      show indexes in `#{ table_name }`
     where key_name = '#{ key_name }'
       and non_unique = #{ non_unique }
    >)
  end

  #
  # Environment
  #

  def master_slave_mode?
    !!ENV['MASTER_SLAVE']
  end

  #
  # Misc
  #

  def capture_stdout
    out = StringIO.new
    $stdout = out
    yield
    return out.string
  ensure
    $stdout = ::STDOUT
  end

  def simulate_failed_migration
    Lhm::Entangler.class_eval do
      alias_method :old_after, :after
      def after
        true
      end
    end

    yield
  ensure
    Lhm::Entangler.class_eval do
      undef_method :after
      alias_method :after, :old_after
      undef_method :old_after
    end
  end
end
