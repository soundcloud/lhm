#
#  copyright (c) 2011, soundcloud ltd., rany keddo, tobias bielohlawek, tobias
#  schmidt
#

module LargeHadronMigrator
  class MysqlTableParser

    def initialize(ddl)
      @ddl = ddl
    end

    def lines
      @ddl.lines.to_a.reject(&:blank?).map(&:strip)
    end

    def create_definitions
      lines[1..-2]
    end

    def parse
      _, name = *lines.first.match("`([^ ]*)`")

      Table.new(name).tap do |table|
        table.table_options = lines.last.gsub(/^\) */, "")
        table.ddl = @ddl

        create_definitions.each do |definition|
          case definition
          when primary_key
            table.primary_key = $1
          when index
            table.indices[$1] = { :metadata => $2 }
          when column
            table.columns[$1] = { :type => $2, :metadata => $3 }
          end
        end
      end
    end

    private

      def primary_key
        /^PRIMARY KEY (?:USING (?:HASH|[BR]TREE) )?\(`([^ ]*)`\),?$/
      end

      def index
        /^(?:UNIQUE )?(?:INDEX|KEY) `([^ ]*)` (.*?),?$/
      end

      def column
        /^`([^ ]*)` ([^ ]*) (.*?),?$/
      end
  end
end
