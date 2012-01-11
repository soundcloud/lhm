#
#  Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
#  Schmidt
#

require 'lhm/table'
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

  private

    def startstamp
      @start.strftime "%Y_%m_%d_%H_%M_%S_#{ "%03d" % (@start.usec / 1000) }"
    end
  end
end

