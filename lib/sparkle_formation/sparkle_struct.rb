require 'sparkle_formation'

class SparkleFormation
  # SparkleFormation customized AttributeStruct
  class SparkleStruct < AttributeStruct
    include ::SparkleFormation::SparkleAttribute
    # @!parse include ::SparkleFormation::SparkleAttribute

    # Set SparkleFormation instance
    #
    # @param inst [SparkleFormation]
    # @return [SparkleFormation]
    def _set_self(inst)
      unless(inst.is_a?(SparkleFormation))
        raise TypeError.new "Expecting type of `SparkleFormation` but got `#{inst.class}`"
      end
      @self = inst
    end

    # @return [SparkleFormation]
    def _self
      unless(@self)
        raise 'Creator did not provide return reference!'
      end
      @self
    end

    # @return [Class]
    def _klass
      ::SparkleFormation::SparkleStruct
    end
  end
end
