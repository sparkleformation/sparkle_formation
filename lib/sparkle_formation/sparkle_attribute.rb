require 'attribute_struct'

module SparkleAttribute

  # TODO: look at the docs for Fn stuff. We can probably just map
  # simple ones with a bit of string manipulations
  
  def _cf_join(*args)
    {'Fn::Join' => ['', *args]}
  end
  
  def _cf_ref(thing)
    thing = _process_key(thing) if thing.is_a?(Symbol)
    {'Ref' => thing}
  end

  def _cf_map(thing, key, *suffix)
    {'Fn::FindInMap' => [_process_key(thing), {'Ref' => _process_key(key)}, *suffix]}
  end

  def _cf_attr(*args)
    args = args.map do |thing|
      if(thing.is_a?(Symbol))
        _process_key(thing)
      else
        thing
      end
    end
    {'Fn::GetAtt' => args}
  end

  def _cf_base64(arg)
    {'Fn::Base64' => arg}
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
  
end

AttributeStruct.send(:include, SparkleAttribute)
