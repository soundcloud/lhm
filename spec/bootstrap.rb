# Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/mock'
require "pathname"

$project = Pathname.new(File.dirname(__FILE__) + '/..').cleanpath
$spec = $project.join("spec")
$fixtures = $spec.join("fixtures")

$: << $project.join("lib").to_s
