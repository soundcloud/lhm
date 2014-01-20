# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require 'lhm/command'
require 'lhm/migration'
require 'lhm/sql_helper'

module Lhm
  # Switches origin with destination table using an atomic rename.
  #
  # It should only be used if the MySQL server version is not affected by the
  # bin log affecting bug #39675. This can be verified using
  # Lhm::SqlHelper.supports_atomic_switch?.
  class AtomicSwitcher
    include Command
    RETRY_SLEEP_TIME = 10
    MAX_RETRIES = 600

    attr_reader :connection, :retries
    attr_writer :max_retries, :retry_sleep_time

    def initialize(migration, connection = nil)
      @migration = migration
      @connection = connection
      @origin = migration.origin
      @destination = migration.destination
      @retries = 0
      @max_retries = MAX_RETRIES
      @retry_sleep_time = RETRY_SLEEP_TIME
    end

    def statements
      atomic_switch
    end

    def atomic_switch
      [
        "rename table `#{ @origin.name }` to `#{ @migration.archive_name }`, " \
        "`#{ @destination.name }` to `#{ @origin.name }`"
      ]
    end

    def validate
      unless @connection.table_exists?(@origin.name) &&
             @connection.table_exists?(@destination.name)
        error "`#{ @origin.name }` and `#{ @destination.name }` must exist"
      end
    end

    private

    def execute
      begin
        @connection.sql(statements)
      rescue ActiveRecord::StatementInvalid => error
        if should_retry_exception?(error) && (@retries += 1) < @max_retries
          sleep(@retry_sleep_time)
          Lhm.logger.warn "Retrying sql=#{statements} error=#{error} retries=#{@retries}"
          retry
        else
          raise
        end
      end
    end

    def should_retry_exception?(error)
      error.message =~ /Lock wait timeout exceeded/
    end
  end
end
