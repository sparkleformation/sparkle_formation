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

namespace :rufo do
  desc 'Validate Ruby file formatting'
  task :validate => [] do
    base_path = File.dirname(__FILE__)
    [
      File.join(base_path, 'lib'),
      File.join(base_path, 'test'),
    ].each do |path|
      if !system("rufo -c #{path}")
        $stderr.puts "Files in #{path} directory require formatting!"
        $stderr.puts "  - Run `rake rufo:fmt`"
        exit -1
      end
    end
  end

  desc 'Format Ruby files in this project'
  task :fmt => [] do
    base_path = File.dirname(__FILE__)
    [
      File.join(base_path, 'lib'),
      File.join(base_path, 'test'),
    ].each do |path|
      $stdout.puts "Formatting files in #{path} directory..."
      system("rufo #{path}")
      if $?.exitstatus != 0 && $?.exitstatus != 3
        $stderr.puts "ERROR: Formatting files in #{path} failed!"
        exit -1
      end
    end
    $stdout.puts " -> File formatting complete!"
  end
end

desc 'Run all tests'
task :default => [] do
  Rake::Task['rufo:validate'].invoke
  Rake::Task[:spec].invoke
  Rake::Task[:test].invoke
end
