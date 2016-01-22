require_relative './candidate'
require_relative './state'

# Delegate/vote counts for a Candidate in a State.
CandidateState = Struct.new(:database, :candidate_id, :state_code, :ballot_order, :n_votes, :n_delegates, :poll_percent, :poll_sparkline) do
  include Comparable

  def candidate; database.candidates.find!(candidate_id); end
  def state; database.states.find!(state_code); end
  def party_id; candidate.party_id; end

  def <=>(rhs)
    c1 = rhs.n_delegates - n_delegates
    if c1 != 0
      c1
    else
      c2 = rhs.n_votes - n_votes
      if c2 != 0
        c2
      else
        ballot_order - rhs.ballot_order
      end
    end
  end
end
