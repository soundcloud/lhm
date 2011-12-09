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
      %Q{
        insert ignore into `#{ destination.name }` #{ destination.columns }
        select #{ self.columns } from `#{ self.name }`
        where id between #{ lowest } and #{ highest }
      }
    end
  end
end
