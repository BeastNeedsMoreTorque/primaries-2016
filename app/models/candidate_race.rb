class CandidateRace
  attr_reader(:candidate, :race)

  def initialize(ap_hash, race)
    @ap_hash = ap_hash
    @race = race
    @candidate = Candidate.find_by_id(@ap_hash[:polID])
    # Hack: this is the only place we find candidate names in AP's API
    @candidate.name = "#{@ap_hash[:first]} #{@ap_hash[:last]}".strip
  end

  def ballot_order; @ap_hash[:ballotOrder]; end
  def party_id; @ap_hash[:party]; end
  def party; Party.find_by_id(party_id); end
  def n_votes; @ap_hash[:voteCount]; end
  def winner; @hash[:winner]; end
end
