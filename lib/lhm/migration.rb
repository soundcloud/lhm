# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require 'lhm/intersection'

module Lhm
  class Migration
    attr_reader :origin, :destination, :conditions, :renames

    def initialize(origin, destination, conditions = nil, renames = {}, time = Time.now)
      @origin = origin
      @destination = destination
      @conditions = conditions
      @start = time
      @renames = renames
    end

    def archive_name
      "lhma_#{ startstamp }_#{ @origin.name }"[0...64]
    end

    def intersection
      Intersection.new(@origin, @destination, @renames)
    end

    def startstamp
      @start.strftime "%Y_%m_%d_%H_%M_%S_#{ "%03d" % (@start.usec / 1000) }"
    end
  end
end
