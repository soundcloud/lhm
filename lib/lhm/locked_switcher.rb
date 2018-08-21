# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require 'lhm/command'
require 'lhm/migration'
require 'lhm/sql_helper'

module Lhm
  # Switches origin with destination table nonatomically using a locked write.
  # LockedSwitcher adopts the Facebook strategy, with the following caveat:
  #
  #   "Since alter table causes an implicit commit in innodb, innodb locks get
  #   released after the first alter table. So any transaction that sneaks in
  #   after the first alter table and before the second alter table gets
  #   a 'table not found' error. The second alter table is expected to be very
  #   fast though because copytable is not visible to other transactions and so
  #   there is no need to wait."
  #
  class LockedSwitcher
    include Command
    include SqlHelper

    attr_reader :connection

    def initialize(migration, connection = nil)
      @migration = migration
      @connection = connection
      @origin = migration.origin
      @destination = migration.destination
    end

    def statements
      uncommitted { switch }
    end

    def switch
      [
        "lock table `#{ @origin.name }` write, `#{ @destination.name }` write",
        "alter table `#{ @origin.name }` rename `#{ @migration.archive_name }`",
        "alter table `#{ @destination.name }` rename `#{ @origin.name }`",
        'commit',
        'unlock tables'
      ]
    end

    def uncommitted
      [
        'set @lhm_auto_commit = @@session.autocommit',
        'set session autocommit = 0',
        yield,
        'set session autocommit = @lhm_auto_commit'
      ].flatten
    end

    def validate
      unless @connection.data_source_exists?(@origin.name) &&
             @connection.data_source_exists?(@destination.name)
        error "`#{ @origin.name }` and `#{ @destination.name }` must exist"
      end
    end

    private

    def revert
      @connection.execute(tagged('unlock tables'))
    end

    def execute
      statements.each do |stmt|
        @connection.execute(tagged(stmt))
      end
    end
  end
end
