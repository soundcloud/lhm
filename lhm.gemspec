# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$:.unshift(lib) unless $:.include?(lib)

require 'lhm/version'

Gem::Specification.new do |s|
  s.name          = "lhm"
  s.version       = Lhm::VERSION
  s.platform      = Gem::Platform::RUBY
  s.authors       = ["SoundCloud", "Rany Keddo", "Tobias Bielohlawek", "Tobias Schmidt"]
  s.email         = %q{rany@soundcloud.com, tobi@soundcloud.com, ts@soundcloud.com}
  s.summary       = %q{online schema changer for mysql}
  s.description   = %q{Migrate large tables without downtime by copying to a temporary table in chunks. The old table is not dropped. Instead, it is moved to timestamp_table_name for verification.}
  s.homepage      = %q{http://github.com/soundcloud/large-hadron-migrator}
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]
  s.executables   = ["lhm-kill-queue"]

  s.add_development_dependency "minitest", "= 2.10.0"
  s.add_development_dependency "rake"
end

