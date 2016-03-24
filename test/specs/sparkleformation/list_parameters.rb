SparkleFormation.new(:list_parameters) do
  parameters do
    basic_string.type 'String'
    comma_list.type 'CommaDelimitedList'
    type_list.type 'List<AWS::EC2::VPC::Id>'
  end
end
