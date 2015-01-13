# Copyright (c) 2011 - 2013, SoundCloud Ltd.

require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'

describe Lhm do

  before(:each) do
    Lhm.remove_class_variable :@@logger if Lhm.class_variable_defined? :@@logger
  end

  describe 'logger' do

    it 'should use the default parameters if no logger explicitly set' do
      Lhm.logger.must_be_kind_of Logger
      Lhm.logger.level.must_equal Logger::INFO
      Lhm.logger.instance_eval { @logdev }.dev.must_equal STDOUT
    end

    it 'should use s new logger if set' do
      l = Logger.new('omg.ponies')
      l.level = Logger::ERROR
      Lhm.logger = l

      Lhm.logger.level.must_equal Logger::ERROR
      Lhm.logger.instance_eval { @logdev }.dev.must_be_kind_of File
      Lhm.logger.instance_eval { @logdev }.dev.path.must_equal 'omg.ponies'
    end
  end
end
