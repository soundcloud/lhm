#
#  Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
#  Schmidt
#
#  Creates entanglement between two tables. All creates, updates and deletes
#  to origin will be repeated on the the destination table.
#

require 'lhm/command'

module Lhm
  class Entangler
    include Command

    attr_reader :epoch

    def initialize(migration, connection = nil)
      @common = migration.intersection
      @origin = migration.origin
      @destination = migration.destination
      @connection = connection
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
        replace into `#{ @destination.name }` (#{ @common.joined })
        values (#{ @common.typed("NEW") })
      }
    end

    def create_trigger_upd
      strip %Q{
        create trigger `#{ trigger(:upd) }`
        after update on `#{ @origin.name }` for each row
        replace into `#{ @destination.name }` (#{ @common.joined })
        values (#{ @common.typed("NEW") })
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

    #
    # Command implementation
    #

    def validate
      unless table?(@origin.name)
        error("#{ @origin.name } does not exist")
      end

      unless table?(@destination.name)
        error("#{ @destination.name } does not exist")
      end
    end

    def before
      sql(entangle)
      @epoch = connection.select_value("select max(id) from #{ @origin.name }").to_i
    end

    def after
      sql(untangle)
    end

    def revert
      after
    end

  private

    def strip(sql)
      sql.strip.gsub(/\n */, "\n")
    end
  end
end

