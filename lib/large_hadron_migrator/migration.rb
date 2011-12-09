#
#  copyright (c) 2011, soundcloud ltd., rany keddo, tobias bielohlawek, tobias
#  schmidt
#
#  copies an origin table to an altered destination table. live activity is
#  synchronized into the destination table using triggers.
#
#  once the origin and destination tables have converged, origin is archived
#  and replaced by destination.
#

module LargeHadronMigrator
  class Migration
    attr_accessor :origin, :destination

    def initialize(origin, connection)
      @alter       = Alter.new(origin)
      @entangler   = Entangler.new(origin, destination)
      @switcher    = LockedSwitcher.new(origin, destination)
      @chunker     = Chunker.new(origin)
      @origin      = MysqlTableParser.new(origin_schema).parse
      @destination = Table.new(destination_name, origin)
      @connection  = connection
      @start       = Time.now

      if satisfies_preconditions?
        sql @destination.ddl
      else
        raise Exception.new("preconditions not satisfied")
      end
    end

    def run
      sql @alter.changes
      sql @entangler.entangle

      @chunker.chunk(@entangler) do |lowest, highest|
        sql @origin.into(@destination, lowest, highest)
      end

      sql @switcher.switch
      sql @entangler.untangle
      sql @origin.rename(archive_name)
    end

    def satisfies_preconditions?
      connection.exists?(@origin.name) &&
        @origin.satisfies_primary_key? &&
        !connection.exists?(@destination.name)
    end

    def archive_name
      "lhma-#{ startstamp }-#{ @origin.name }"
    end

    def destination_name
      "lhmd-#{ @origin.name }"
    end

    def origin_schema
      connection.select_one "show create table #{ @origin.name }"
    end

    private

      def sql(ddl)
        connection.execute(ddl)
      end

      def startstamp
        @start.strftime("%Y_%m_%d_%H_%M_%S_#{ "%03d" % (@start.usec / 1000) }")
      end
  end
end
