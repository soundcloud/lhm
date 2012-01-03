#
#  copyright (c) 2011, soundcloud ltd., rany keddo, tobias bielohlawek, tobias
#  schmidt
#
#  Switches the names of two tables with a write lock. Use this as a safe
#  alternative to rename, which can cause data inconsistencies:
#
#    http://bugs.mysql.com/bug.php?id=39675
#

module LargeHadronMigrator
  class LockedSwitcher
    def initialize(origin, destination, archive)
      @origin = origin
      @destination = destination
      @archive = archive
    end

    def switch
      [
        "set @lhm_auto_commit = @@session.autocommit"
        "set session autocommit = 0",
        "lock table `#{ @origin }` write, `#{ @destination }` write",
        "alter table `#{ @origin }` rename `#{ @archive }`",
        "alter table `#{ @destination }` rename `#{ @origin }`",
        "commit",
        "unlock tables",
        "set session autocommit = @lhm_auto_commit"
      ]
    end
  end
end

