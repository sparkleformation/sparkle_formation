SparkleFormation.new(:complex) do
  core_block :core
  test_value :core
end.load(:base).overrides do
  override_value :core
end
