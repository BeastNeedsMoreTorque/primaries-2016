CountyParty = RubyImmutableStruct.new(:database, :fips_int, :party_id, :n_precincts_reporting, :n_precincts_total, :last_updated) do
  attr_reader(:id)

  def after_initialize
    @id = "#{@fips_int}-#{@party_id}"
  end
end
