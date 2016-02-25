# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'

require 'lhm/invoker'

describe Lhm::Invoker do
  include UnitHelper

  before(:each) do
    @origin = MiniTest::Mock.new
    @origin.expect(:destination_name, 1)
    @connection = MiniTest::Mock.new

    @invoker = Lhm::Invoker.new(@origin, @connection)
  end

  it 'should lower isolation level when asked' do
    @connection.expect(:execute, 1) do |stmt|
      expected = 'SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED'
      stmt == expected || stmt == [expected]
    end
    @invoker.set_session_isolation_level(lower_isolation_level: true)
    @connection.verify
  end

  it 'leaves isolation levels alone by default' do
    @invoker.set_session_isolation_level({})
  end
end
