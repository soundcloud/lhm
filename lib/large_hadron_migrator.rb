#
#  Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
#  Schmidt
#

require 'large_hadron_migrator/alter'
require 'large_hadron_migrator/chunker'
require 'large_hadron_migrator/entangler'
require 'large_hadron_migrator/intersection'
require 'large_hadron_migrator/locked_switcher'
require 'large_hadron_migrator/migration'
require 'large_hadron_migrator/mysql_table_parser'
require 'large_hadron_migrator/table'

module LargeHadronMigrator
  VERSION = "0.9.0"

  def hadron_change_table(name, &block)
    migration = Migration.new(name, connection)
    block.call(migration.alter)
    migration.run
  end
end

