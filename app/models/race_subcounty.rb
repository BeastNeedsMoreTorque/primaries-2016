RaceSubcounty = RubyImmutableStruct.new(:database, :race_id, :geo_id, :n_votes, :n_precincts_reporting, :n_precincts_total) do
  attr_reader(:id, :party_id)

  def after_initialize
    @id = "#{@race_id}-#{@geo_id}"
    @party_id = @race_id[11..13]
  end
end