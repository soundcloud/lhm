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

    def initialize(origin, destination, epoch = 1)
      @common = Intersection.new(origin, destination)
      @origin = origin
      @destination = destination
      @epoch = epoch
    end

    def entangle
      [
        create_trigger_del,
        create_trigger_ins,
        create_trigger_upd
      ]
    end

    def untangle
      [
        "drop trigger if exists `#{ trigger(:del) }`",
        "drop trigger if exists `#{ trigger(:ins) }`",
        "drop trigger if exists `#{ trigger(:upd) }`"
      ]
    end

    def create_trigger_ins
      strip %Q{
        create trigger `#{ trigger(:ins) }`
        after insert on `#{ @origin.name }` for each row
        replace into `#{ @destination.name }` #{ @common.joined }
        values #{ @common.typed("NEW") }
      }
    end

    def create_trigger_upd
      strip %Q{
        create trigger `#{ trigger(:upd) }`
        after update on `#{ @origin.name }` for each row
        replace into `#{ @destination.name }` #{ @common.joined }
        values #{ @common.typed("NEW") }
      }
    end

    def create_trigger_del
      strip %Q{
        create trigger `#{ trigger(:del) }`
        after delete on `#{ @origin.name }` for each row
        delete ignore from `#{ @destination.name }`
        where `#{ @destination.name }`.`id` = OLD.`id`
      }
    end


    def trigger(type)
      "lhmt_#{ type }_#{ @origin.name }"
    end

    private

      def strip(sql)
        sql.strip.gsub(/\n */, "\n")
      end
  end
end

