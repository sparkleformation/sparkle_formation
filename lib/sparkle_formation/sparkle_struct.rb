require 'sparkle_formation'

class SparkleFormation
  # SparkleFormation customized AttributeStruct
  class SparkleStruct < AttributeStruct
    include ::SparkleFormation::SparkleAttribute
    # @!parse include ::SparkleFormation::SparkleAttribute

    # @return [Class]
    def _klass
      ::SparkleFormation::SparkleStruct
    end
  end
end
