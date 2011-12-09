#
#  copyright (c) 2011, soundcloud ltd., rany keddo, tobias bielohlawek, tobias
#  schmidt
#
#  Creates entanglement between two tables. All creates, updates and deletes
#  to origin will be repeated on the the destination table.
#

module LargeHadronMigrator
  class Entangler
    attr_accessor :epoch

    def initialize(origin, destination, epoch)
      @origin = origin
      @destination = destination
      @epoch = epoch
    end

    def entangle
      create_trigger_del + create_trigger_ins + create_trigger_upd
    end

    def untangle
      %Q{
        drop trigger if exists #{ trigger(:del) };
        drop trigger if exists #{ trigger(:ins) };
        drop trigger if exists #{ trigger(:upd) };
      }
    end

    def create_trigger_del
      %Q{
        create trigger #{ trigger(:del) }
        after delete on `#{ @origin.name }`
        for each row delete ignore from `#{ @destination.name }`
        where `#{ @destination.name }`.`id` = old.`id`;
      }
    end

    def create_trigger_ins
      %Q{
        create trigger #{ trigger(:ins) }
        after insert on `#{ @origin.name }`
        for each row replace into `#{ @destination.name }` #{ @origin.columns }
        values #{ @destination.columns };
      }
    end

    def create_trigger_upd
      %Q{
        create trigger #{ trigger(:upd) }
        after update on `#{ @origin.name }`
        for each row replace into `#{ @destination.name }` #{ @origin.columns }
        values #{ @destination.columns };
      }
    end

    def trigger(type)
      "lhm-trigger-#{ type }"
    end
  end
end
