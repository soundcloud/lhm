# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require 'lhm/table'
require 'lhm/invoker'
require 'lhm/connection'
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
  # @param [Hash] options Optional options to alter the chunk / switch behavior
  # @option options [Fixnum] :stride
  #   Size of a chunk (defaults to: 40,000)
  # @option options [Fixnum] :throttle
  #   Time to wait between chunks in milliseconds (defaults to: 100)
  # @option options [Boolean] :atomic_switch
  #   Use atomic switch to rename tables (defaults to: true)
  #   If using a version of mysql affected by atomic switch bug, LHM forces user
  #   to set this option (see SqlHelper#supports_atomic_switch?)
  # @yield [Migrator] Yielded Migrator object records the changes
  # @return [Boolean] Returns true if the migration finishes
  # @raise [Error] Raises Lhm::Error in case of a error and aborts the migration
  def self.change_table(table_name, options = {}, &block)
    origin = Table.parse(table_name, connection)
    invoker = Invoker.new(origin, connection)
    block.call(invoker.migrator)
    invoker.run(options)

    true
  end

  def self.cleanup(run = false)
    lhm_tables = connection.select_values("show tables").select do |name|
      name =~ /^lhm(a|n)_/
    end
    return true if lhm_tables.empty?
    if run
      lhm_tables.each do |table|
        connection.execute("drop table #{table}")
      end
      true
    else
      puts "Existing LHM backup tables: #{lhm_tables.join(", ")}."
      puts "Run Lhm.cleanup(true) to drop them all."
      false
    end
  end

  def self.setup(adapter)
    @@adapter = adapter
  end

  def self.adapter
    @@adapter ||=
      begin
        raise 'Please call Lhm.setup' unless defined?(ActiveRecord)
        ActiveRecord::Base.connection
      end
  end

  protected
  def self.connection
    Connection.new(adapter)
  end

end
