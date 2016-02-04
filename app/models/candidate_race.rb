# Vote counts for a Candidate in a Race
#
# See also CandidateState. They aren't the same thing: there can be two races
# in one state with the same candidate.
CandidateRace = RubyImmutableStruct.new(:database_or_nil, :candidate_id, :race_id, :ballot_order, :n_votes, :percent_vote, :leader, :ap_says_winner, :huffpost_says_winner) do
  include Comparable

  attr_reader(:id, :candidate, :candidate_state, :state_code)

  def after_initialize
    @id = "#{@candidate_id}-#{@race_id}"

    if database_or_nil
      @state_code = @race_id[-2..-1]
      @candidate = database_or_nil.candidates.find!(@candidate_id)
      @candidate_state = database_or_nil.candidate_states.find("#{@candidate_id}-#{@state_code}") # may be nil
    end
  end

  def n_delegates; @candidate_state.n_delegates; end
  def poll_sparkline; @candidate_state.poll_sparkline; end
  def poll_percent; @candidate_state.poll_percent; end
  def candidate_last_name; @candidate.name; end
  def winner?; ap_says_winner || huffpost_says_winner; end
  def leader?; @leader; end

  def <=>(rhs)
    c1 = (rhs.n_votes || 0) - (n_votes || 0)
    if c1 != 0
      c1
    else
      c2 = (rhs.n_delegates || 0) - (n_delegates || 0)
      if c2 != 0
        c2
      else
        candidate_last_name <=> rhs.candidate_last_name
      end
    end
  end
end
