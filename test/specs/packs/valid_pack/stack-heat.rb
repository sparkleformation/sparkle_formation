SparkleFormation.new(:stack, :provider => :heat) do
  heat_template true
  dynamic!(:base)
  registry registry!(:base)
  shared_item registry!(:shared, :provider => :shared)
end.load(:base)
