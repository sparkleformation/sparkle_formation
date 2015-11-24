SparkleFormation.new('nest') do
  nest!(:dummy)
  nest!(:simple)
  nest!(:dummy, :second)
  nest!(:dummy, :third, :overwrite_name => true)
end
