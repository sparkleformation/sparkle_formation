SparkleFormation.new(:core) do
  dynamic!(:base, :core)
  registry_item_value registry!(:item)
end.load(:base)
