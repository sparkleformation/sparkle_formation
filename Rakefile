require 'bundler/setup'
require 'rake/testtask'
require 'rubocop/rake_task'

RuboCop::RakeTask.new

Rake::TestTask.new do |test|
  test.pattern = 'test/**/*_spec.rb'
  test.verbose = true
end

task :default => [] do
  Rake::Task[:rubocop].invoke
  Rake::Task[:test].invoke
end
