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

require 'sparkle_formation'

class SparkleFormation

  # Provides template helper methods
  module SparkleAttribute

    # Fn::Join generator
    #
    # @param args [Object]
    # @return [Hash]
    def _cf_join(*args)
      options = args.detect{|i| i.is_a?(Hash) && i[:options]} || {:options => {}}
      args.delete(options)
      unless(args.size == 1)
        args = [args]
      end
      {'Fn::Join' => [options[:options][:delimiter] || '', *args]}
    end
    alias_method :join!, :_cf_join

    # Ref generator
    #
    # @param thing [String, Symbol] reference name
    # @return [Hash]
    # @note Symbol value will force key processing
    def _cf_ref(thing)
      thing = _process_key(thing, :force) if thing.is_a?(Symbol)
      {'Ref' => thing}
    end
    alias_method :_ref, :_cf_ref
    alias_method :ref!, :_cf_ref

    # Fn::FindInMap generator
    #
    # @param thing [String, Symbol] thing to find
    # @param key [String, Symbol] thing to search
    # @param suffix [Object] additional args
    # @return [Hash]
    def _cf_map(thing, key, *suffix)
      suffix = suffix.map do |item|
        if(item.is_a?(Symbol))
          _process_key(item, :force)
        else
          item
        end
      end
      thing = _process_key(thing, :force) if thing.is_a?(Symbol)
      key = _process_key(key, :force) if key.is_a?(Symbol)
      {'Fn::FindInMap' => [_process_key(thing), {'Ref' => _process_key(key)}, *suffix]}
    end
    alias_method :_cf_find_in_map, :_cf_map
    alias_method :find_in_map!, :_cf_map
    alias_method :map!, :_cf_map

    # Fn::GetAtt generator
    #
    # @param [Object] pass through arguments
    # @return [Hash]
    def _cf_attr(*args)
      args = args.map do |thing|
        if(thing.is_a?(Symbol))
          _process_key(thing, :force)
        else
          thing
        end

      end
      {'Fn::GetAtt' => args}
    end
    alias_method :_cf_get_att, :_cf_attr
    alias_method :get_att!, :_cf_attr
    alias_method :attr!, :_cf_attr

    # Fn::Base64 generator
    #
    # @param arg [Object] pass through
    # @return [Hash]
    def _cf_base64(arg)
      {'Fn::Base64' => arg}
    end
    alias_method :base64!, :_cf_base64

    # Fn::GetAZs generator
    #
    # @param region [String, Symbol] String will pass through. Symbol will be converted to ref
    # @return [Hash]
    def _cf_get_azs(region=nil)
      region = case region
               when Symbol
                 _cf_ref(region)
               when NilClass
                 ''
               else
                 region
               end
      {'Fn::GetAZs' => region}
    end
    alias_method :get_azs!, :_cf_get_azs
    alias_method :azs!, :_cf_get_azs

    # Fn::Select generator
    #
    # @param index [String, Symbol, Integer] Symbol will be converted to ref
    # @param item [Object, Symbol] Symbol will be converted to ref
    # @return [Hash]
    def _cf_select(index, item)
      index = index.is_a?(Symbol) ? _cf_ref(index) : index
      item = _cf_ref(item) if item.is_a?(Symbol)
      {'Fn::Select' => [index, item]}
    end
    alias_method :select!, :_cf_select

    # @return [TrueClass, FalseClass]
    def rhel?
      !!@platform[:rhel]
    end

    # @return [TrueClass, FalseClass]
    def debian?
      !!@platform[:debian]
    end

    # Set the destination platform
    #
    # @param plat [String, Symbol] one of :rhel or :debian
    # @return [TrueClass]
    def _platform=(plat)
      @platform || __hashish
      @platform.clear
      @platform[plat.to_sym] = true
    end

    # Dynamic insertion helper method
    #
    # @param name [String, Symbol] dynamic name
    # @param args [Object] argument list for dynamic
    # @return [self]
    def dynamic!(name, *args, &block)
      SparkleFormation.insert(name, self, *args, &block)
    end

    # Registry insertion helper method
    #
    # @param name [String, Symbol] name of registry item
    # @param args [Object] argument list for registry
    # @return [self]
    def registry!(name, *args)
      SfnRegistry.insert(name, self, *args)
    end

  end
end
