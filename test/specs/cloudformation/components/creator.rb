SparkleFormation.component(:user_info) do
  parameters.creator do
    type 'String'
    default 'Fubar'
  end
  output.creator do
    description 'Stack creator'
    value ref!(:creator)
  end
end
