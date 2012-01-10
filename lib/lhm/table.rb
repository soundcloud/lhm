#
#  Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
#  Schmidt
#

module Lhm
  class Table
    attr_reader :name, :columns, :indices
    attr_accessor :primary_key, :table_options, :ddl

    def initialize(table_name)
      @name = table_name
      @columns = {}
      @indices = {}
    end

    def satisfies_primary_key?
      primary_key == "id"
    end

    def destination_name
      "lhmd_#{ @name }"
    end

    def idx_name(cols)
      "index_#{ @name }_on_" + [*cols].join("_and_")
    end

    def self.parse(table_name, connection)
      sql = "show create table `#{ table_name }`"
      ddl = connection.select_one(sql)["Create Table"]
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
end

