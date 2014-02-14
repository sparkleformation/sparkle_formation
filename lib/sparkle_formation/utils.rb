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

class SparkleFormation
  module Utils

    module AnimalStrings

      def camel(string)
        string.to_s.split('_').map{|k| "#{k.slice(0,1).upcase}#{k.slice(1,k.length)}"}.join
      end

      def snake(string)
        string.to_s.gsub(/([a-z])([A-Z])/, '\1_\2').downcase.to_sym
      end

    end

  end

  class Registry

    class << self

      def init!
        @register = AttributeStruct.hashish.new
        self
      end

      def register(name, &block)
        @register[name] = block
      end

      def insert(name, location, *args)
        if(block = @register[name])
          location.instance_exec(*args, &block)
        else
          raise KeyError.new("Requested item not found in registry (#{name})")
        end
      end

    end

  end
end


SfnRegistry = SparkleFormation::Registry.init!
