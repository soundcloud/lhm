#
#  Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
#  Schmidt
#
#  Determine and format columns common to origin and destination.
#

module Lhm
  class Intersection
    def initialize(origin, destination)
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
      escaped.join(", ")
    end

    def typed(type)
      common.map { |name| qualified(name, type)  }.join(", ")
    end

  private

    def qualified(name, type)
      "#{ type }.`#{ name }`"
    end

    def tick(name)
      "`#{ name }`"
    end
  end
end

