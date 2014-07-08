# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt
require 'test_helper'

module UnitHelper
  def fixture(name)
    File.read $fixtures.join(name)
  end

  def strip(sql)
    sql.strip.gsub(/\n */, "\n")
  end
end
