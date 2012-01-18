#
#  Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
#  Schmidt
#

require 'active_record'
require 'lhm/table'
require 'lhm/invoker'
require 'lhm/version'

module Lhm
  extend self

  def change_table(table_name, chunk_options = {}, &block)
    connection = ActiveRecord::Base.connection
    origin = Table.parse(table_name, connection)
    invoker = Invoker.new(origin, connection)
    block.call(invoker.migrator)
    invoker.run(chunk_options)
  end
end
