SparkleFormation.dynamic(:base, :layering => :merge) do |name, args = {}|
  expanded_dynamic name
  args[:previous_layer_result]
end
