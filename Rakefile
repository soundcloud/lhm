require 'rake/testtask'
require 'bundler'

Bundler::GemHelper.install_tasks

Rake::TestTask.new("unit") do |t|
  t.libs.push "lib"
  t.test_files = FileList['spec/unit/*_spec.rb']
  t.verbose = true
end

Rake::TestTask.new("integration") do |t|
  t.libs.push "lib"
  t.test_files = FileList['spec/integration/*_spec.rb']
  t.verbose = true
end

task :specs => [:unit, :integration]
task :default => :specs

task :console do
  require 'irb'
  require 'irb/completion'
  require 'lhm'
  require 'byebug'
  ARGV.clear
  IRB.start
end
