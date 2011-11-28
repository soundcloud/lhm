# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name          = "large_hadron_migrator"
  s.version       = File.read("VERSION").to_s
  s.platform      = Gem::Platform::RUBY
  s.authors       = ["SoundCloud", "Rany Keddo", "Tobias Bielohlawek"]
  s.email         = %q{rany@soundcloud.com, tobi@soundcloud.com}
  s.summary       = %q{online schema changer for mysql}
  s.description   = %q{Migrate large tables without downtime by copying to a temporary table in chunks. The old table is not dropped. Instead, it is moved to timestamp_table_name for verification.}
  s.homepage      = %q{http://github.com/soundcloud/large-hadron-migrator}
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "activerecord", "~> 2.3.8"
  s.add_dependency "activesupport", "~> 2.3.8"

  # this should be a real dependency, but we're using a different gem in our code
  s.add_development_dependency "mysql", "~> 2.8.1"
  s.add_development_dependency "rspec", "=1.3.1"
  s.add_development_dependency "rake"
end
