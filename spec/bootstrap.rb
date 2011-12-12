#
#  copyright (c) 2011, soundcloud ltd., rany keddo, tobias bielohlawek, tobias
#  schmidt
#

require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/mock'
require "pathname"

$project = Pathname.new(File.dirname(__FILE__) + '/..').cleanpath
$spec = $project.join("spec")
$fixtures = $spec.join("fixtures")

$: << $project.join("lib").to_s

require 'active_record'
require 'large_hadron_migrator'
