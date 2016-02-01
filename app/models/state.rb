State = RubyImmutableStruct.new(:database, :fips_int, :code, :abbreviation, :name, :n_dem_delegates, :n_gop_delegates) do
  def id; code; end

  def to_json(*a)
    JSON.generate({
      fipsInt: fips_int,
      code: code,
      abbreviation: abbreviation,
      name: name
    }, *a)
  end

  def n_delegates(party_id); send("n_#{party_id.downcase}_delegates"); end

  def is_actual_state?; fips_int < 60 && fips_int > 0; end
end
