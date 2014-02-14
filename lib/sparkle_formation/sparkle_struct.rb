require 'sparkle_formation'

class SparkleFormation
  class SparkleStruct < AttributeStruct
    include ::SparkleFormation::SparkleAttribute

    def _klass
      ::SparkleFormation::SparkleStruct
    end
  end
end
