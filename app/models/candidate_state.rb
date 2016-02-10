# Delegate counts and poll results for a Candidate in a State.
#
# See also CandidateRace. They aren't the same thing: there can be two races
# in one state with the same candidate.
CandidateState = RubyImmutableStruct.new(:database, :candidate_id, :state_code, :n_delegates, :poll_percent, :poll_sparkline) do
  include Comparable

  attr_reader(:id, :candidate, :party_id, :state)

  def after_initialize
    @id = "#{candidate_id}-#{state_code}"
    @candidate = database.candidates.find!(candidate_id)
    @party_id = @candidate.party_id
    @state = database.states.find!(state_code)
  end

  def candidate_last_name; candidate.name; end

  def <=>(rhs)
    c1 = rhs.n_delegates - n_delegates
    if c1 != 0
      c1
    else
      c2 = (rhs.poll_percent || 0) - (poll_percent || 0)
      if c2 != 0
        c2
      else
        candidate_last_name <=> rhs.candidate_last_name
      end
    end
  end
end
