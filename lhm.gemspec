# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$:.unshift(lib) unless $:.include?(lib)

require 'lhm'

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
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # this should be a real dependency, but we're using a different gem in our code
  s.add_development_dependency "mysql", "~> 2.8.1"
  s.add_development_dependency "rspec", "=1.3.1"
  s.add_development_dependency "rake"

  s.add_dependency "active_record"
end

