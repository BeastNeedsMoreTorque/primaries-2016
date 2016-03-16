# Delegate counts and poll results for a Candidate in a State.
#
# See also CandidateRace. They aren't the same thing: there can be two races
# in one state with the same candidate.
CandidateState = RubyImmutableStruct.new(:database, :candidate_id, :state_code, :n_delegates, :n_pledged_delegates, :poll_percent, :poll_sparkline) do
  include Comparable

  attr_reader(:id, :candidate, :party, :party_id, :party_state, :party_state_id, :state)

  def after_initialize
    @id = "#{@candidate_id}-#{@state_code}"
    @candidate = database.candidates.find!(@candidate_id)
    @party = @candidate.party
    @party_id = @party.id
    @party_state_id = "#{@party_id}-#{@state_code}"
    @party_state = database.party_states.find!(@party_state_id)
    @state = database.states.find!(@state_code)
  end

  def candidate_last_name; candidate.name; end
  def candidate_slug; candidate.slug; end
  def state_name; state.name; end
  def has_delegates?; n_delegates > 0; end
  def has_pledged_delegates?; n_pledged_delegates > 0; end

  def <=>(rhs)
    # Sort by party first, so iterating over all candidate_states will return
    # "Dem" before "GOP"
    x = party_id <=> rhs.party_id
    return x if x != 0

    # When we're looking at many for the same candidate, sort by state name
    x = state_name <=> rhs.state_name
    return x if x != 0

    # When we're looking at many for the same state, sort by winning candidates
    x = rhs.n_delegates - n_delegates
    return x if x != 0

    x = (rhs.poll_percent || 0) - (poll_percent || 0)
    return x if x != 0

    return candidate_last_name <=> rhs.candidate_last_name
  end
end
