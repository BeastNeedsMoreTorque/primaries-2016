PartyState = RubyImmutableStruct.new(:database, :party_id, :state_code, :n_delegates, :n_pledged_delegates, :pollster_slug, :pollster_last_updated) do
  attr_reader(:id)

  def after_initialize
    @id = "#{@party_id}-#{@state_code}"
  end

  def candidate_states
    database.candidate_states.find_all_by_party_state_id(@id)
  end

  def n_delegates_with_candidates
    candidate_states.map(&:n_delegates).reduce(0, :+)
  end

  def n_pledged_delegates_with_candidates
    candidate_states.map(&:n_pledged_delegates).reduce(0, :+)
  end
end
