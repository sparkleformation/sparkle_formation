SparkleFormation.new(:complex_inherit, :inherit => :complex) do
  override_value :inherit
end.overrides do
  test_value :inherit
end
