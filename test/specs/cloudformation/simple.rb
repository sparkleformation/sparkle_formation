SparkleFormation.new('simple').load(:user_info).overrides do
  dynamic!(:node, 'fubar')
  outputs.region do
    description 'Region of stack'
    value region!
  end
end
