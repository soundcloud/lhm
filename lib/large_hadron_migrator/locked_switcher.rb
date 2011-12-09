#
#  copyright (c) 2011, soundcloud ltd., rany keddo, tobias bielohlawek, tobias
#  schmidt
#
#  Switches the names of two tables with a write lock.
#

module LargeHadronMigrator
  class LockedSwitcher
    def initialize(left, right)
      @left = left
      @right = right
    end
  end
end
