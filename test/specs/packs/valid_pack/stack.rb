SparkleFormation.new(:stack).load(:base) do
  aws_template true
  dynamic!(:base)
  registry registry!(:base)
  shared_item registry!(:shared, :provider => :shared)
end
