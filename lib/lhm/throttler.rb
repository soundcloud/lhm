require 'lhm/throttler/time'

module Lhm
  module Throttler
    CLASSES = { :time_throttler => Throttler::Time }

    def throttler
      @throttler ||= Throttler::Time.new
    end

    def setup_throttler(type, options = {})
      @throttler = Factory.create_throttler(type, options)
    end

    class Factory
      def self.create_throttler(type, options = {})
        case type
        when Fixnum
          # we still support the throttle as a Fixnum input
          warn "throttler option will no loger accept a Fixnum in the next versions."
          legacy_throttler(type)
        when Lhm::Command
          type
        when Symbol
          CLASSES[type].new(options)
        when String
          CLASSES[type.to_sym].new(options)
        when Class
          type.new(options)
        else
          raise ArgumentError, 'type argument must be a Symbol, String or Class'
        end
      end

      def self.legacy_throttler(t)
        Throttler::LegacyTime.new(t)
      end
    end
  end
end
