#
#  Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
#  Schmidt
#
#  Copies an origin table to an altered destination table. Live activity is
#  synchronized into the destination table using triggers.
#
#  Once the origin and destination tables have converged, origin is archived
#  and replaced by destination.
#

require 'lhm/chunker'
require 'lhm/entangler'
require 'lhm/locked_switcher'
require 'lhm/migration'
require 'lhm/migrator'

module Lhm
  class Invoker
    attr_reader :migrator

    def initialize(origin, connection)
      @connection = connection
      @migrator = Migrator.new(origin, connection)
    end

    def run
      migration = @migrator.run

      Entangler.new(migration, @connection).run do |tangler|
        Chunker.new(migration, tangler.epoch, @connection).run
        LockedSwitcher.new(migration, @connection).run
      end
    end
  end
end

