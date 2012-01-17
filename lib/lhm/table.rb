#
#  Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
#  Schmidt
#

module Lhm
  class Table
    attr_reader :name, :columns, :indices, :pk, :ddl

    def initialize(name, pk = "id", ddl = nil)
      @name = name
      @columns = {}
      @indices = {}
      @pk = pk
      @ddl = ddl
    end

    def satisfies_primary_key?
      @pk == "id"
    end

    def destination_name
      "lhmn_#{ @name }"
    end

    def idx_name(cols)
      column_part = Array(cols).map { |c| c.to_s.sub(/\(.*/, "") }.join("_and_")
      "index_#{ @name }_on_#{ column_part }"
    end

    def self.parse(table_name, connection)
      sql = "show create table `#{ table_name }`"
      ddl = connection.execute(sql).fetch_row.last

      Parser.new(ddl).parse
    end

    class Parser
      def initialize(ddl)
        @ddl = ddl
      end

      def lines
        @ddl.lines.to_a.map(&:strip).reject(&:empty?)
      end

      def create_definitions
        lines[1..-2]
      end

      def parse
        _, name = *lines.first.match("`([^ ]*)`")
        pk_line = create_definitions.grep(primary).first

        if pk_line
          _, pk = *pk_line.match(primary)
          table = Table.new(name, pk, @ddl)

          create_definitions.each do |definition|
            case definition
              when index
                table.indices[$1] = { :metadata => $2 }
              when column
                table.columns[$1] = { :type => $2, :metadata => $3 }
            end
          end

          table
        end
      end

    private

      def primary
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
end

