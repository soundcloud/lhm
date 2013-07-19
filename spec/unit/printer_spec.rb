require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'

require 'lhm/printer'

describe Lhm::Printer do
  include UnitHelper

  describe "percentage printer" do

    before(:each) do
      @printer = Lhm::Printer::Percentage.new
    end

    it "prints the percentage" do
      mock = MiniTest::Mock.new
      10.times do |i|
        mock.expect(:write, :return_value) do |message|
          assert_match /^\r/, message.first
          assert_match /#{i}\/10/, message.first
        end
      end

      @printer.instance_variable_set(:@output, mock)
      10.times { |i| @printer.notify(i, 10) }
      mock.verify
    end

    it "always print a bigger message" do
      @length = 0
      mock = MiniTest::Mock.new
      3.times do |i|
        mock.expect(:write, :return_value) do |message|
          assert message.first.length >= @length
          @length = message.first.length
        end
      end

      @printer.instance_variable_set(:@output, mock)
      @printer.notify(10, 100)
      @printer.notify(0, 100)
      @printer.notify(1, 1000000)
      @printer.notify(0, 0)

      mock.verify
    end

    it "prints the end message" do
      mock = MiniTest::Mock.new
      mock.expect(:write, :return_value, [String])
      mock.expect(:write, :return_value, ["\n"])

      @printer.instance_variable_set(:@output, mock)
      @printer.end

      mock.verify
    end
  end

  describe "dot printer" do

    before(:each) do
      @printer = Lhm::Printer::Dot.new
    end

    it "prints the dots" do
      mock  = MiniTest::Mock.new
      10.times do
        mock.expect(:write, :return_value, ["."])
      end

      @printer.instance_variable_set(:@output, mock)
      10.times { @printer.notify }

      mock.verify
    end

  end
end
