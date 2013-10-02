# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require 'lhm/intersection'

module Lhm
  class Migration
    attr_reader :origin, :destination, :conditions, :order_column

    def initialize(origin, destination, order_column, conditions = nil, time = Time.now)
      @origin = origin
      @destination = destination
      @conditions = conditions
      @order_column = order_column
      @start = time
    end

    def archive_name
      "lhma_#{ startstamp }_#{ @origin.name }"[0...64]
    end

    def intersection
      Intersection.new(@origin, @destination)
    end

    def startstamp
      @start.strftime "%Y_%m_%d_%H_%M_%S_#{ "%03d" % (@start.usec / 1000) }"
    end
  end
end
