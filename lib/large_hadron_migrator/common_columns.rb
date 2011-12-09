#
#  copyright (c) 2011, soundcloud ltd., rany keddo, tobias bielohlawek, tobias
#  schmidt
#
#  Determine and format columns common to origin and destination.
#

module LargeHadronMigrator
  class CommonColumns
    def initializer(origin, destination)
      @origin = origin
      @destination = destination
    end

    def common
      @origin.columns.keys & @destination.columns.keys
    end

    def escaped
      common.map { |name| tick(name)  }
    end

    def joined
      common.join(", ")
    end

    def typed(type)
      common.map { |name| typed(name, type)  }
    end

    private

      def tick(name)
        "`#{ name }`"
      end

      def typed(name, type)
        "`#{ type }.#{ name }`"
      end
  end
end

