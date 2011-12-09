#
#  copyright (c) 2011, soundcloud ltd., rany keddo, tobias bielohlawek, tobias
#  schmidt
#

require File.expand_path(File.dirname(__FILE__)) + "/../bootstrap"

module UnitHelper
  def fixture(name)
    File.read $fixtures.join(name)
  end
end
