require_relative './candidate'
require_relative './state'

# Delegate/vote counts for a Candidate in a State.
CandidateState = Struct.new(:candidate_id, :state_code, :ballot_order, :n_votes, :n_delegates) do
  include Comparable

  def candidate; Candidate.find(candidate_id); end
  def state; State.find_by_code(state_code); end
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

  def self.find_all_by_party_id_and_state_code(party_id, state_code)
    if !@by_party_id_and_state_code
      @by_party_id_and_state_code ||= all.group_by { |cs| "#{cs.party_id}-#{cs.state_code}" }
      @by_party_id_and_state_code.values.each(&:sort!)
    end
    @by_party_id_and_state_code["#{party_id}-#{state_code}"] || []
  end

  def self.all=(v); @all = v; end
  def self.all; @all; end
end
