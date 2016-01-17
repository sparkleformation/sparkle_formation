#
# Author:: Chris Roberts <chris@hw-ops.com>
# Copyright:: 2013, Heavy Water Operations, LLC
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'bogo'
require 'multi_json'
require 'attribute_struct'

# Unicorns and rainbows
class SparkleFormation
  autoload :Aws, 'sparkle_formation/aws'
  autoload :Error, 'sparkle_formation/error'
  autoload :FunctionStruct, 'sparkle_formation/function_struct'
  autoload :Provider, 'sparkle_formation/provider'
  autoload :Resources, 'sparkle_formation/resources'
  autoload :Sparkle, 'sparkle_formation/sparkle'
  autoload :SparkleCollection, 'sparkle_formation/sparkle_collection'
  autoload :SparkleAttribute, 'sparkle_formation/sparkle_attribute'
  autoload :SparkleStruct, 'sparkle_formation/sparkle_struct'
  autoload :Utils, 'sparkle_formation/utils'
  autoload :Translation, 'sparkle_formation/translation'
  autoload :Version, 'sparkle_formation/version'
end

require 'sparkle_formation/sparkle_formation'
