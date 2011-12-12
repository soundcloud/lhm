#
#  Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
#  Schmidt
#

module LargeHadronMigrator
  class Alter
    attr_accessor :name, :changes

    def initialize(table)
      @table = table
      @name = @table.name
      @changes = []
    end

    def ddl(statement)
      changes << statement
    end

    def add_column(name, definition = "")
      ddl = "alter table `%s` add column `%s` %s" % [@name, name, definition]
      changes << ddl.strip
    end

    def remove_column(name)
      ddl = "alter table `%s` drop `%s`" % [@name, name]
      changes << ddl.strip
    end

    def add_index(cols, option = "")
      ddl = "create index `%s` on %s %s" % [idx_name(cols), idx_spec(cols), option]
      changes << ddl.strip
    end

    def remove_index(cols)
      ddl = "drop index `%s` on `%s`" % [idx_name(cols), @name]
      changes << ddl.strip
    end

    def idx_name(cols)
      [*cols].join("_and_") + "_index"
    end

    private

      def idx_spec(cols)
        "#{ @name }(#{ cols.join(', ') })"
      end
  end
end

