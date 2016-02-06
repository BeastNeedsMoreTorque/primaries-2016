CountyRace = RubyImmutableStruct.new(:database, :fips_int, :race_id, :n_votes, :n_precincts_reporting, :n_precincts_total) do
  attr_reader(:id, :party_id)

  def after_initialize
    @id = "#{@fips_int}-#{@race_id}"
    @party_id = @race_id[11..13]
  end
end
