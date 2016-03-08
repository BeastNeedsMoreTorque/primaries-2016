RaceSubcounty = RubyImmutableStruct.new(:database, :race_id, :geo_id, :n_votes, :n_precincts_reporting, :n_precincts_total) do
  attr_reader(:id, :party_id)

  def after_initialize
    @id = "#{@race_id}-#{@geo_id}"
    @party_id = @race_id[11..13]
  end

  def leader
    first = database.candidate_race_subcounties.find_all_by_race_subcounty_id(id).first
    first.n_votes > 0 ? first : nil
  end

  def leader_slug
    x = leader
    x.nil? ? nil : x.candidate_slug
  end
end
