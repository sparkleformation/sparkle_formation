require "bundler/setup"
require "rake/testtask"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |task|
  task.rspec_opts = "--pattern test/rspecs/**{,/*/**}/*_rspec.rb"
end

Rake::TestTask.new do |test|
  test.pattern = "test/**/*_spec.rb"
  test.verbose = true
end

desc "Run all tests"
task :default => [] do
  Rake::Task[:spec].invoke
  Rake::Task[:test].invoke
end
