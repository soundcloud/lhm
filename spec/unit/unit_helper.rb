#
#  Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
#  Schmidt
#

require File.expand_path(File.dirname(__FILE__)) + "/../bootstrap"

module UnitHelper
  def fixture(name)
    File.read $fixtures.join(name)
  end

  def strip(sql)
    sql.strip.gsub(/\n */, "\n")
  end
end

