require 'sparkle_formation'
require 'minitest/autorun'

Dir.glob(File.join(File.expand_path(File.dirname(__FILE__)), 'specs/*.rb')).each do |path|
  require path
end
