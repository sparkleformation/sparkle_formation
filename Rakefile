require 'bundler/setup'
require 'rake/testtask'
require 'rubocop/rake_task'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |task|
  task.rspec_opts = "--pattern test/rspecs/**{,/*/**}/*_rspec.rb"
end
RuboCop::RakeTask.new

Rake::TestTask.new do |test|
  test.pattern = 'test/**/*_spec.rb'
  test.verbose = true
end

task :default => [] do
  Rake::Task[:rubocop].invoke
  Rake::Task[:spec].invoke
  Rake::Task[:test].invoke
end
