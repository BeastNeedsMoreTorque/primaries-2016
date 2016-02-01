County = RubyImmutableStruct.new(:database, :fips_int) do
  alias_method(:id, :fips_int)
end
