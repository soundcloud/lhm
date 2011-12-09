#
#  Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
#  Schmidt
#

module LargeHadronMigrator
  class Alter
    attr_accessor :name

    def initialize(table)
      @table = table
      @name = @table.name
    end

    def changes
      %Q{

      }
    end
  end
end

