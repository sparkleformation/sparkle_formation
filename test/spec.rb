require 'sparkle_formation'
require 'minitest/autorun'

def capture_stdout
  old, $stdout = $stdout, StringIO.new
  yield
  $stdout.string
ensure
  $stdout = old
end

SparkleFormation.sparkle_path = File.join(
  File.dirname(__FILE__), 'specs', 'sparkleformation'
)
