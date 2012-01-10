#
#  Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
#  Schmidt
#
#  Copies existing schema and applies changes using alter on the empty table.
#  `run` returns a Migration which can be used for the remaining process.
#

require 'lhm/command'
require 'lhm/migration'

module Lhm
  class Migrator
    include Command

    attr_reader :name, :statements

    def initialize(table, connection = nil)
      @connection = connection
      @origin = table
      @name = table.destination_name
      @statements = []
    end

    def ddl(statement)
      statements << statement
    end

    def add_column(name, definition = "")
      ddl = "alter table `%s` add column `%s` %s" % [@name, name, definition]
      statements << ddl.strip
    end

    def remove_column(name)
      ddl = "alter table `%s` drop `%s`" % [@name, name]
      statements << ddl.strip
    end

    def add_index(cols)
      ddl = "create index `%s` on %s" % [@origin.idx_name(cols), idx_spec(cols)]
      statements << ddl.strip
    end

    def remove_index(*cols)
      ddl = "drop index `%s` on `%s`" % [@origin.idx_name(cols), @name]
      statements << ddl.strip
    end

    #
    # Command implementation
    #

    def validate
      unless table?(@origin.name)
        error("could not find origin table #{ @origin.name }")
      end

      unless @origin.satisfies_primary_key?
        error("origin does not satisfy primary key requirements")
      end

      dest = @origin.destination_name

      if table?(dest)
        error("#{ dest } should not exist; not cleaned up from previous run?")
      end
    end

  private

    def execute
      destination_create
      sql(@statements)
      Migration.new(@origin, destination_read)
    end

    def destination_create
      original = "CREATE TABLE `#{ @origin.name }`"
      replacement = "CREATE TABLE `#{ @origin.destination_name }`"

      sql(@origin.ddl.gsub(original, replacement))
    end

    def destination_read
      Table.parse(@origin.destination_name, connection)
    end

    def idx_spec(cols)
      "#{ @name }(#{ [*cols].map(&:to_s).join(', ') })"
    end
  end
end

