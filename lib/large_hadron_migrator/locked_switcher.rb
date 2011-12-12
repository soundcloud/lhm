#
#  copyright (c) 2011, soundcloud ltd., rany keddo, tobias bielohlawek, tobias
#  schmidt
#
#  Switches the names of two tables with a write lock.
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
        "set session autocommit=0",
        "lock table `#{ @origin }` write, `#{ @destination }` write",
        "alter table `#{ @origin }` rename `#{ @archive }`",
        "alter table `#{ @destination }` rename `#{ @origin }`",
        "commit",
        "unlock tables",
        "set session autocommit=1"
      ]
    end
  end
end

