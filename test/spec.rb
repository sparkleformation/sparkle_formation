require 'sparkle_formation'
require 'minitest/autorun'

def capture_stdout
  old, $stdout = $stdout, StringIO.new
  yield
  $stdout.string
ensure
  $stdout = old
end

$sparkle_path_spec = File.join(
  File.dirname(__FILE__), 'specs', 'sparkleformation'
)
SparkleFormation.sparkle_path = $sparkle_path_spec
