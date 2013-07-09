require 'lhm/throttle/time'

module Lhm
  module Throttle
    CLASSES = {:time_throttle => Throttle::Time}

    def throttle
      @throttle ||= Throttle::Time.new
    end

    def setup_throttle(type, options = {})
      @throttle = Factory.create_throttle(type, options)
    end

    class Factory

      def self.create_throttle(type, options = {})
        case type
        when Fixnum
          # we still support the throttle as a Fixnum input
          warn "throttle option will no loger accept a Fixnum in the next versions."
          legacy_throttle(type)
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

      def self.legacy_throttle(t)
        Throttle::LegacyTime.new(t)
      end
    end

  end
end
