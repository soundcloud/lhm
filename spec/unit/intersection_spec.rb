# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require File.expand_path(File.dirname(__FILE__)) + '/unit_helper'

require 'lhm/table'
require 'lhm/migrator'

describe Lhm::Intersection do
  include UnitHelper

  it "should not have dropped changes" do
    origin = Lhm::Table.new("origin")
    origin.columns["dropped"]  = varchar
    origin.columns["retained"] = varchar

    destination = Lhm::Table.new("destination")
    destination.columns["retained"] = varchar

    intersection = Lhm::Intersection.new(origin, destination)
    intersection.common.include?("dropped").must_equal(false)
  end

  it "should have unchanged columns" do
    origin = Lhm::Table.new("origin")
    origin.columns["dropped"]  = varchar
    origin.columns["retained"] = varchar

    destination = Lhm::Table.new("destination")
    destination.columns["retained"] = varchar

    intersection = Lhm::Intersection.new(origin, destination)
    intersection.common.must_equal(["retained"])
  end

  def varchar
    { :metadata => "VARCHAR(255)"}
  end
end
