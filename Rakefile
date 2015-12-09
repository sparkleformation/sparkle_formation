require "bundler/setup"
require "rake/testtask"

Rake::TestTask.new do |test|
  test.pattern = 'test/**/*_spec.rb'
  test.verbose = true
end

task :default => :test
