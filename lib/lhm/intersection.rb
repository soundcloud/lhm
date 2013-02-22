# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

module Lhm
  #  Determine and format columns common to origin and destination.
  class Intersection
    def initialize(origin, destination)
      @origin = origin
      @destination = destination
    end

    def common
      (@origin.columns.keys & @destination.columns.keys).sort
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
