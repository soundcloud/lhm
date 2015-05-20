# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

module Lhm
  #  Determine and format columns common to origin and destination.
  class Intersection
    def initialize(origin, destination, renames = {})
      @origin = origin
      @destination = destination
      @renames = renames
    end

    def origin
      (common + @renames.keys).extend(Joiners)
    end

    def destination
      (common + @renames.values).extend(Joiners)
    end

    private

    def common
      (@origin.columns.keys & @destination.columns.keys).sort
    end

    module Joiners
      def escaped
        map { |name| tick(name)  }
      end

      def joined
        escaped.join(', ')
      end

      def typed(type)
        map { |name| qualified(name, type)  }.join(', ')
      end

      private

      def qualified(name, type)
        "`#{ type }`.`#{ name }`"
      end

      def tick(name)
        "`#{ name }`"
      end
    end
  end
end
