require 'rake'

#############################################################################
#
# Helper functions
#
#############################################################################

def name
  @name ||= Dir['*.gemspec'].first.split('.').first
end

def gemspec_file
  "#{name}.gemspec"
end

def gemspec
  @gemspec ||= eval(IO.read(gemspec_file))
end

def gem_file
  gemspec.file_name
end

#############################################################################
#
# Standard tasks
#
#############################################################################

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "large_hadron_migration"
    gem.summary = %Q{online schema changer for mysql}
    gem.description = %Q{Migrate large tables without downtime by copying to a temporary table in chunks. The old table is not dropped. Instead, it is moved to timestamp_table_name for verification.}
    gem.email = "rany@soundcloud.com, tobi@soundcloud.com"
    gem.homepage = "http://github.com/soundcloud/large_hadron_migration"
    gem.authors = ["SoundCloud", "Rany Keddo", "Tobias Bielohlawek"]
    gem.add_development_dependency "activerecord", "= 2.3.5"
    gem.add_development_dependency "activesupport", "= 2.3.5"
    gem.add_development_dependency "rspec", "= 1.3.0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  #Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

#task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "large_hadron_migration #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc "Deploys the builded gem to the soundcloud gem repository: gems.soundcloud.com"
task :release => :build do
  remote_gem_host = 'soundcloud@gems.int.s-cloud.net'
  remote_gem_path = '/srv/www/gems'
  Dir.chdir File.dirname(__FILE__)
  unless `git branch` =~ /^\* master$/
    puts "You must be on the master branch to release!"
    exit!
  end
  if `git fetch --tags && git tag`.split(/\n/).include?(gem_file)
    raise "Version #{gem_file} already deployed"
  end
  sh <<-END
    git commit -a --allow-empty -m 'Release #{gem_file}'
    git tag -a #{gem_file} -m 'Version #{gem_file}'
    git push origin master
    git push origin --tags
    scp pkg/#{gem_file} #{remote_gem_host}:#{remote_gem_path}/gems && \
    ssh #{remote_gem_host} 'gem generate_index -d #{remote_gem_path}'
  END
end
