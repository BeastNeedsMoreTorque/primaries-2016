require_relative './candidate'
require_relative './candidate_county'
require_relative './candidate_state'
require_relative './party'
require_relative './race_day'
require_relative './state'

# Could be called PartyState. Gives the votes/delegates of a state.
Race = Struct.new(:ap_id, :race_day_id, :party_id, :state_code, :race_type, :n_precincts_reporting, :n_precincts_total, :last_updated) do
  def party; Party.find(party_id); end
  def race_day; RaceDay.find(race_day_id); end
  def state; State.find_by_code(state_code); end

  def candidate_states
    @candidate_states ||= if ap_id
      CandidateState.find_all_by_party_id_and_state_code(party_id, state_code)
        .sort { |a, b| b.n_delegates - a.n_delegates || b.n_votes - a.n_votes || a.ballot_position - b.ballot_position }
    else
      []
    end
  end

  # Returns a Race ... or nil if there won't be one.
  #
  # (Colorado Republicans  won't vote for a presidential nominee in 2016.)
  def self.find_by_party_and_state(party, state)
    @by_party_and_state ||= @all.map{ |r| [ "#{r.party.id}-#{r.state.code}", r ] }.to_h
    @by_party_and_state["#{party.id}-#{state.code}"]
  end

  def self.all=(v); @all = v; end
  def self.all; @all; end
end
