SparkleFormation.new(:hash_loading) do
  value([
    :fubar => 'hi',
    :nested => {
      :fubar => true,
    },
  ])
end
