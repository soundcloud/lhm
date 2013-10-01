# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require 'lhm/table'
require 'lhm/invoker'
require 'lhm/connection'
require 'lhm/throttle'
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
  extend Throttle
  extend self

  # Alters a table with the changes described in the block
  #
  # @param [String, Symbol] table_name Name of the table
  # @param [Hash] options Optional options to alter the chunk / switch behavior
  # @option options [Fixnum] :stride
  #   Size of a chunk (defaults to: 40,000)
  # @option options [Fixnum] :throttle
  #   Time to wait between chunks in milliseconds (defaults to: 100)
  # @option options [Fixnum] :start
  #   Primary Key position at which to start copying chunks
  # @option options [Fixnum] :limit
  #   Primary Key position at which to stop copying chunks
  # @option options [Boolean] :atomic_switch
  #   Use atomic switch to rename tables (defaults to: true)
  #   If using a version of mysql affected by atomic switch bug, LHM forces user
  #   to set this option (see SqlHelper#supports_atomic_switch?)
  # @yield [Migrator] Yielded Migrator object records the changes
  # @return [Boolean] Returns true if the migration finishes
  # @raise [Error] Raises Lhm::Error in case of a error and aborts the migration
  def change_table(table_name, options = {}, &block)
    origin = Table.parse(table_name, connection)
    invoker = Invoker.new(origin, connection)
    block.call(invoker.migrator)
    invoker.run(options)
    true
  end

  def cleanup(run = false)
    lhm_tables = connection.select_values("show tables").select { |name| name =~ /^lhm(a|n)_/ }
    lhm_triggers = connection.select_values("show triggers").collect do |trigger|
      trigger.respond_to?(:trigger) ? trigger.trigger : trigger
    end.select { |name| name =~ /^lhmt/ }

    if run
      lhm_triggers.each do |trigger|
        connection.execute("drop trigger #{trigger}")
      end
      lhm_tables.each do |table|
        connection.execute("drop table #{table}")
      end
      true
    elsif lhm_tables.empty? && lhm_triggers.empty?
      puts "Everything is clean. Nothing to do."
      true
    else
      puts "Existing LHM backup tables: #{lhm_tables.join(", ")}."
      puts "Existing LHM triggers: #{lhm_triggers.join(", ")}."
      puts "Run Lhm.cleanup(true) to drop them all."
      false
    end
  end

  def setup(adapter)
    @@adapter = adapter
  end

  def adapter
    @@adapter ||=
      begin
        raise 'Please call Lhm.setup' unless defined?(ActiveRecord)
        ActiveRecord::Base.connection
      end
  end

  protected

  def connection
    Connection.new(adapter)
  end

end
