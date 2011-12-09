#
#  Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
#  Schmidt
#

require 'large_hadron_migrator/table'
require 'large_hadron_migrator/migration'
require 'large_hadron_migrator/mysql_table_parser'

module LargeHadronMigrator
  VERSION = "0.9.0"

  def hadron_change_table(name, &block)
    migration = Migration.new(name, connection)
    block.call(migration.destination)
    migration.run
  end
end

