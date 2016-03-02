CandidateRaceDay = RubyImmutableStruct.new(:database, :candidate_id, :race_day_id) do
  attr_reader(:id, :candidate, :candidate_races, :n_delegates, :n_pledged_delegates)

  def after_initialize
    @id = "#{@candidate_id}-#{@race_day_id}"
    @candidate = @database.candidates.find!(@candidate_id)
    @race_day = @database.race_days.find!(@race_day_id)
    @candidate_races = @race_day.candidate_races.select { |cr| cr.candidate_id == @candidate_id }
    @n_delegates = @candidate_races.map(&:n_delegates).reduce(0, :+)
    @n_pledged_delegates = @candidate_races.map(&:n_pledged_delegates).reduce(0, :+)
  end

  def candidate_last_name; candidate.last_name; end
  def candidate_slug; candidate.slug; end
  def candidate_states; candidate_races.map(&:candidate_state); end
  def party_id; candidate.party_id; end

  def leads_candidate_races
    candidate_races.select(&:leader?)
  end
end
