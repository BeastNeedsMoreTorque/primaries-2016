PartyRaceDay = RubyImmutableStruct.new(:database, :party_id, :race_day_id) do
  attr_reader(:id, :candidate_races, :candidate_states, :race_day, :races, :party_states, :n_delegates, :n_pledged_delegates)

  def after_initialize
    @id = "#{@party_id}-#{@race_day_id}"
    @races = @database.races.find_all_by_party_race_day_id(@id)
    @race_day = @database.race_days.find!(@race_day_id)
    @candidate_races = @races.flat_map(&:candidate_races)
    @candidate_states = @races.flat_map(&:candidate_states)
    @party_states = @races.map(&:party_state)
    @n_delegates = @party_states.map(&:n_delegates).reduce(0, :+)
    @n_pledged_delegates = @party_states.map(&:n_pledged_delegates).reduce(0, :+)
  end

  def candidate_race_days
    database.candidate_race_days.find_all_by_race_day_id(@race_day_id).select { |crd| crd.party_id === @party_id }
  end

  def party; database.parties.find!(party_id); end
  def party_adjective; party.adjective; end
  def party_name; party.name; end

  def n_delegates_up_for_grabs
    n_delegates - candidate_states.map(&:n_delegates).reduce(0, :+)
  end

  def n_pledged_delegates_up_for_grabs
    n_pledged_delegates - n_pledged_delegates_with_candidates
  end

  def n_pledged_delegates_with_candidates
    candidate_states.map(&:n_pledged_delegates).reduce(0, :+)
  end

  def races_without_leaders
    used_state_codes = candidate_races.select(&:leader?).map(&:state_code).to_set

    candidate_races.map(&:race)
      .reject { |r| used_state_codes.include?(r.state_code) }
      .uniq
  end

  def horse_race_data
    {
      title: race_day.title,
      n_pledged_delegates: n_pledged_delegates,
      races: races.map(&:horse_race_data),
      candidates: candidate_race_days
        .map { |crd| { id: crd.candidate_id, n_delegates: crd.n_pledged_delegates } }
    }
  end
end
