# Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require 'active_record'
require 'lhm/table'
require 'lhm/invoker'
require 'lhm/version'

# Large hadron migrator - online schema change tool
#
# @example
#
#   Lhm.change_table(:users) do |m|
#     m.add_column(:arbitrary, "INT(12)")
#     m.add_index([:arbitrary, :created_at])
#     m.ddl("alter table %s add column flag tinyint(1)" % m.name)
#   end
#
module Lhm

  # Alters a table with the changes described in the block
  #
  # @param [String, Symbol] table_name Name of the table
  # @param [Hash] chunk_options Optional options to alter the chunk behavior
  # @option chunk_options [Fixnum] :stride
  #   Size of a chunk (defaults to: 40,000)
  # @option chunk_options [Fixnum] :throttle
  #   Time to wait between chunks in milliseconds (defaults to: 100)
  # @yield [Migrator] Yielded Migrator object records the changes
  # @return [Boolean] Returns true if the migration finishes
  # @raise [Error] Raises Lhm::Error in case of a error and aborts the migration
  def self.change_table(table_name, chunk_options = {}, &block)
    connection = ActiveRecord::Base.connection
    origin = Table.parse(table_name, connection)
    invoker = Invoker.new(origin, connection)
    block.call(invoker.migrator)
    invoker.run(chunk_options)

    true
  end
end

