# Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require 'lhm/chunker'
require 'lhm/entangler'
require 'lhm/locked_switcher'
require 'lhm/migrator'

module Lhm
  # Copies an origin table to an altered destination table. Live activity is
  # synchronized into the destination table using triggers.
  #
  # Once the origin and destination tables have converged, origin is archived
  # and replaced by destination.
  class Invoker
    attr_reader :migrator

    def initialize(origin, connection)
      @connection = connection
      @migrator = Migrator.new(origin, connection)
    end

    def run(chunk_options = {})
      migration = @migrator.run

      Entangler.new(migration, @connection).run do
        Chunker.new(migration, @connection, chunk_options).run
        LockedSwitcher.new(migration, @connection).run
      end
    end
  end
end
