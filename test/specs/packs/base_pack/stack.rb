::SparkleFormation::SparklePack.register!('external_sparkle_pack', File.join(File.dirname(__FILE__), '..', 'external_sparkle_pack'))
add_on_pack = ::SparkleFormation::SparklePack.new(:name => 'external_sparkle_pack')
SparkleFormation.new(:stack, :sparkle => add_on_pack) do
  dynamic!(:add_on)
  dynamic!(:base)
end
