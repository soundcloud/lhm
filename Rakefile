require 'rake/testtask'
require 'bundler'

Bundler::GemHelper.install_tasks

Rake::TestTask.new('unit') do |t|
  t.libs << 'lib'
  t.libs << 'spec'
  t.test_files = FileList['spec/unit/**/*_spec.rb']
  t.verbose = true
end

Rake::TestTask.new('integration') do |t|
  t.libs << 'lib'
  t.libs << 'spec'
  t.test_files = FileList['spec/integration/**/*_spec.rb']
  t.verbose = true
end

task :specs => [:unit, :integration]
task :default => :specs
