require 'sparkle_formation'
require 'pp'
require 'json'

puts JSON.pretty_generate(
  SparkleFormation.compile(
    File.join(
      File.dirname(__FILE__),
      'cloudformation/ec2_example.rb'
    )
  )
)
