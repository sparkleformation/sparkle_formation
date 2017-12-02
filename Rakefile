require 'bundler/setup'
require 'rake/testtask'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |task|
  task.rspec_opts = "--pattern test/rspecs/**{,/*/**}/*_rspec.rb"
end

Rake::TestTask.new do |test|
  test.pattern = 'test/**/*_spec.rb'
  test.verbose = true
end

task :rufo => [] do
  base_path = File.dirname(__FILE__)
  [
    File.join(base_path, 'lib'),
    File.join(base_path, 'test'),
  ].each do |path|
    if !system("rufo -c #{path}")
      $stderr.puts "Files in #{path} directory require formatting!"
      exit -1
    end
  end
end

task :default => [] do
  Rake::Task[:rufo].invoke
  Rake::Task[:spec].invoke
  Rake::Task[:test].invoke
end
