#
#  copyright (c) 2011, soundcloud ltd., rany keddo, tobias bielohlawek, tobias
#  schmidt
#

module LargeHadronMigrator
  class Table
    attr_accessor :name, :primary_key, :table_options, :ddl
    attr_accessor :columns, :indices

    def initialize(name, template = nil)
      @name = name

      self.columns = {}
      self.indices = {}
    end

    def satisfies_primary_key?
      self.primary_key == "id"
    end

    def into(destination, lowest, highest)
      cols = CommonColumns.new(self, destination)

      %Q{
        insert ignore into `#{ destination.name }` (#{ cols.joined  })
        select #{ cols.joined } from `#{ self.name }`
        where id between #{ lowest } and #{ highest }
      }
    end

    def rename(name)
      "rename table `#{ self.name }` `#{ name }`"
    end
  end
end

