# A person who wants to be president
class Candidate
  attr_accessor(:name) # We load this later, in CandidateRace

  def initialize(candidate_country)
    @candidate_country = candidate_country
  end

  def id; @candidate_country.candidate_id; end
  def party_id; @candidate_country.party_id; end

  def candidate_states
    @candidate_states ||= CandidateState.all.select { |cs| cs.candidate_id == id && !!cs.state }
  end

  def candidate_state(state)
    CandidateState.by_candidate_and_state(self, state)
  end

  def party; Party.find_by_id(party_id); end
  def n_delegates; @candidate_country.n_delegates; end
  def n_unpledged_delegates; @candidate_country.n_unpledged_delegates; end

  def self.find_by_id(id)
    by_id.fetch(id.to_s)
  end

  def self.include?(id)
    by_id.include?(id.to_s)
  end

  def self.all
    @all ||= CandidateState.all.select{ |cs| !cs.state }.map{ |cs| Candidate.new(cs) }
  end

  private

  def self.by_id
    @by_id ||= all.map{ |c| [ c.id, c ] }.to_h
  end
end
