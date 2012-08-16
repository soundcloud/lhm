# Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require 'lhm/intersection'

module Lhm
  class Migration
    attr_reader :origin, :destination

    def initialize(origin, destination, time = Time.now)
      @origin = origin
      @destination = destination
      @start = time
    end

    def archive_name
      "lhma_#{ startstamp }_#{ @origin.name }"
    end

    def intersection
      Intersection.new(@origin, @destination)
    end

    def startstamp
      (@start.to_f * 1000).round
    end
  end
end
