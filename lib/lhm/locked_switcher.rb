#
#  Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
#  Schmidt
#
#  Switches origin with destination table with a write lock. Use this as a safe
#  alternative to rename, which can cause slave inconsistencies:
#
#    http://bugs.mysql.com/bug.php?id=39675
#

require 'lhm/command'
require 'lhm/migration'

module Lhm
  class LockedSwitcher
    include Command

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
        "commit",
        "unlock tables"
      ]
    end

    def uncommitted(&block)
      [
        "set @lhm_auto_commit = @@session.autocommit",
        "set session autocommit = 0",
        *yield,
        "set session autocommit = @lhm_auto_commit"
      ]
    end

    #
    # Command interface
    #

    def validate
      unless table?(@origin.name) && table?(@destination.name)
        error "`#{ @origin.name }` and `#{ @destination.name }` must exist"
      end
    end

    def revert
      sql "unlock tables"
    end

  private

    def execute
      sql statements
    end
  end
end

