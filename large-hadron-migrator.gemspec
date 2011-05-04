# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name          = "large-hadron-migrator"
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

  ['activerecord ~>2.3.8', 'activesupport ~>2.3.8', 'mysql =2.8.1'].each do |gem|
    s.add_dependency *gem.split(' ')
  end

  ['rspec =1.3.1'].each do |gem|
    s.add_development_dependency *gem.split(' ')
  end
end
