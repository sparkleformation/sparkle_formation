require 'bogo'
require 'multi_json'
require 'attribute_struct'

# Unicorns and rainbows
class SparkleFormation
  autoload :Aws, 'sparkle_formation/aws'
  autoload :Composition, 'sparkle_formation/composition'
  autoload :Error, 'sparkle_formation/error'
  autoload :FunctionStruct, 'sparkle_formation/function_struct'
  autoload :GoogleStruct, 'sparkle_formation/function_struct'
  autoload :JinjaExpressionStruct, 'sparkle_formation/function_struct'
  autoload :JinjaStatementStruct, 'sparkle_formation/function_struct'
  autoload :Provider, 'sparkle_formation/provider'
  autoload :Resources, 'sparkle_formation/resources'
  autoload :Sparkle, 'sparkle_formation/sparkle'
  autoload :SparklePack, 'sparkle_formation/sparkle'
  autoload :SparkleCollection, 'sparkle_formation/sparkle_collection'
  autoload :SparkleAttribute, 'sparkle_formation/sparkle_attribute'
  autoload :SparkleStruct, 'sparkle_formation/sparkle_struct'
  autoload :TerraformStruct, 'sparkle_formation/function_struct'
  autoload :Utils, 'sparkle_formation/utils'
  autoload :Translation, 'sparkle_formation/translation'
  autoload :Version, 'sparkle_formation/version'
end

require 'sparkle_formation/sparkle_formation'
