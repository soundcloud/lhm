# Copyright (c) 2011, SoundCloud Ltd.

require 'lhm/connection'

describe Lhm::Connection do
  it 'raises an exception when it cannot find the dependencies' do
    assert_raises(NameError) do
      Connection.new({})
    end
  end
end
