#
#  Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
#  Schmidt
#

require 'lhm/table'
require 'lhm/invoker'
require 'lhm/migration'

module Lhm
  VERSION = "1.0.0-RC1"

  def hadron_change_table(table_name, &block)
    origin = Table.parse(table_name, connection)
    invoker = Invoker.new(origin, connection)
    block.call(invoker.migrator)
    invoker.run
  end
end

