# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'

require 'lhm/table'
require 'lhm/migration'
require 'lhm/chunker'
require 'lhm/throttler'

describe Lhm::Checkpointer do
  include UnitHelper

  before(:each) do
    @connection = MiniTest::Mock.new
    # This is a poor man's stub
    @throttler = Object.new
    def @throttler.run
      # noop
    end
  end

  describe 'disabled #run' do

    before(:each) do
      @checkpointer = Lhm::Checkpointer.new(@connection, :start => 1)
    end

    it 'should so nothing' do
      @connection.expect(:table_exists?, false) do |name|
        name.is_a?(String)
      end
      @checkpointer.run {}
    end

    it 'should so bail if table exists' do
      @connection.expect(:table_exists?, true) do |name|
        name.is_a?(String)
      end

      assert_raises Lhm::Error do
        @checkpointer.run {}
      end
    end
  end

  describe 'enabled #run' do

    before(:each) do
      @checkpointer = Lhm::Checkpointer.new(@connection, :start => 1, :checkpoint => true)
    end

    it 'checkpoints on first run' do
      @connection.expect(:table_exists?, false) do |name|
        name.is_a?(String)
      end

      @connection.expect(:execute, true) do |stmt|
        stmt =~ /create table/
      end

      @connection.expect(:execute, true) do |stmt|
        stmt =~ /insert into .* values \( 'last', 1 \)/
      end

      @connection.expect(:select_value, 1) do |stmt|
        stmt =~ /select value from/
      end

      @connection.expect(:execute, true) do |stmt|
        stmt =~ /insert into .* values \( 'last', 10 \)/
      end

      @connection.expect(:select_value, 10) do |stmt|
        stmt =~ /select value from/
      end

      @checkpointer.run {}
      @checkpointer.start.must_equal(1)
      @checkpointer.checkpoint(10)
      @checkpointer.start.must_equal(10)
    end

  end
end
