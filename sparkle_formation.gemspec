$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__)) + '/lib/'
require 'sparkle_formation/version'
Gem::Specification.new do |s|
  s.name = 'sparkle_formation'
  s.version = SparkleFormation::VERSION.version
  s.summary = 'Cloud Formation builder'
  s.author = 'Chris Roberts'
  s.email = 'chrisroberts.code@gmail.com'
  s.homepage = 'http://github.com/heavywater/sparkle_formation'
  s.description = 'Cloud Formation builder'
  s.license = 'Apache-2.0'
  s.require_path = 'lib'
  s.add_dependency 'attribute_struct', '~> 0.1.8'
  s.files = Dir['**/*']
end
