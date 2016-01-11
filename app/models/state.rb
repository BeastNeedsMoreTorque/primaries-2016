State = Struct.new(:database, :fips_int, :code, :abbreviation, :name) do
  def id; code; end

  def to_json(*a)
    JSON.generate({
      fipsInt: fips_int,
      code: code,
      abbreviation: abbreviation,
      name: name
    }, *a)
  end

  def is_actual_state?; fips_int < 60 && fips_int > 0; end
end
