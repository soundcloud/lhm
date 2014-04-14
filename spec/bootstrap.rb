# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/mock'
require "pathname"

$project = Pathname.new(File.dirname(__FILE__) + '/..').cleanpath
$spec = $project.join("spec")
$fixtures = $spec.join("fixtures")

$: << $project.join("lib").to_s

require "lhm"
