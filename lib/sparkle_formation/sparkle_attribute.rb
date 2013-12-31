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

require 'attribute_struct'

module SparkleAttribute

  def _cf_join(*args)
    options = args.detect{|i| i.is_a?(Hash) && i[:options]} || {:options => {}}
    args.delete(options)
    unless(args.size == 1)
      args = [args]
    end
    {'Fn::Join' => [options[:options][:delimiter] || '', *args]}
  end

  def _cf_ref(thing)
    thing = _process_key(thing, :force) if thing.is_a?(Symbol)
    {'Ref' => thing}
  end
  alias_method :_ref, :_cf_ref

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

  def _cf_base64(arg)
    {'Fn::Base64' => arg}
  end

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

  def _cf_select(index, item)
    item = _cf_ref(item) if item.is_a?(Symbol)
    {'Fn::Select' => [index.to_i.to_s, item]}
  end

  def rhel?
    !!@platform[:rhel]
  end

  def debian?
    !!@platform[:debian]
  end

  def _platform=(plat)
    @platform || __hashish
    @platform.clear
    @platform[plat.to_sym] = true
  end

  def dynamic!(name, *args)
    SparkleFormation.insert(name, self, *args)
  end

  def registry!(name, *args)
    SfnRegistry.insert(name, self, *args)
  end

end

AttributeStruct.send(:include, SparkleAttribute)
