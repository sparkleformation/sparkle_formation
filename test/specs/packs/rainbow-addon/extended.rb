SparkleFormation.new(:extended, :layering => :merge) do
  dynamic!(:base, :extended).return_value 'test'
  layered_extra true
end
