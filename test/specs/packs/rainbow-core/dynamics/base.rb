SparkleFormation.dynamic(:base) do |name, args = {}|
  result = set!("#{name}_custom_block".to_sym) do
    base_dynamic true
  end
  outputs.name.value "BASE"
  result
end
