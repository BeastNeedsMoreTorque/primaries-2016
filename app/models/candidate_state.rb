require_relative './candidate'
require_relative './state'

# Delegate/vote counts for a Candidate in a State.
CandidateState = RubyImmutableStruct.new(:database_or_nil, :candidate_id, :state_code, :ballot_order, :n_votes, :n_delegates, :poll_percent, :poll_sparkline) do
  include Comparable

  def id; "#{candidate_id}-#{state_code}"; end

  def candidate; database_or_nil.candidates.find!(candidate_id); end
  def state; database_or_nil.states.find!(state_code); end
  def party_id; candidate.party_id; end

  def <=>(rhs)
    c1 = rhs.n_delegates - n_delegates
    if c1 != 0
      c1
    else
      c2 = (rhs.n_votes || 0) - (n_votes || 0)
      if c2 != 0
        c2
      else
        c3 = (rhs.poll_percent || 0) - (poll_percent || 0)
        if c3 != 0
          c3
        else
          (ballot_order || 0) - (rhs.ballot_order || 0)
        end
      end
    end
  end
end
