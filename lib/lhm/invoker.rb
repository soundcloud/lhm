# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require 'lhm/chunker'
require 'lhm/entangler'
require 'lhm/atomic_switcher'
require 'lhm/locked_switcher'
require 'lhm/migrator'

module Lhm
  # Copies an origin table to an altered destination table. Live activity is
  # synchronized into the destination table using triggers.
  #
  # Once the origin and destination tables have converged, origin is archived
  # and replaced by destination.
  class Invoker
    include SqlHelper
    LOCK_WAIT_TIMEOUT_DELTA = -2

    attr_reader :migrator, :connection

    def initialize(origin, connection)
      @connection = connection
      @migrator = Migrator.new(origin, connection)
    end

    def set_session_lock_wait_timeouts
      global_innodb_lock_wait_timeout = @connection.execute("SHOW GLOBAL VARIABLES LIKE 'innodb_lock_wait_timeout'").first.last.to_i
      global_lock_wait_timeout = @connection.execute("SHOW GLOBAL VARIABLES LIKE 'lock_wait_timeout'").first.last.to_i

      @connection.execute("SET SESSION innodb_lock_wait_timeout=#{global_innodb_lock_wait_timeout + LOCK_WAIT_TIMEOUT_DELTA}") 
      @connection.execute("SET SESSION lock_wait_timeout=#{global_lock_wait_timeout + LOCK_WAIT_TIMEOUT_DELTA}")
    end

    def run(options = {})
      if !options.include?(:atomic_switch)
        if supports_atomic_switch?
          options[:atomic_switch] = true
        else
          raise Error.new(
            "Using mysql #{version_string}. You must explicitly set " +
            "options[:atomic_switch] (re SqlHelper#supports_atomic_switch?)")
        end
      end

      set_session_lock_wait_timeouts

      migration = @migrator.run

      Entangler.new(migration, @connection).run do
        Chunker.new(migration, @connection, options).run
        if options[:atomic_switch]
          AtomicSwitcher.new(migration, @connection).run
        else
          LockedSwitcher.new(migration, @connection).run
        end
      end
    end
  end
end
