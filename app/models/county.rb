County = Struct.new(:database, :fips_int) do
  def id; fips_int; end
end
