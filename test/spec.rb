require 'sparkle_formation'
require 'minitest/autorun'

Dir.glob(
  File.join(
    File.expand_path(
      File.dirname(__FILE__)
    ),
    'specs/**/**/*_spec.rb'
  )
).each do |path|
  require path
end

SparkleFormation.sparkle_path = File.join(
  File.dirname(__FILE__), 'specs', 'sparkleformation'
)
