require_relative './candidate'
require_relative './county'

CandidateCounty = Struct.new(:candidate_id, :county_id, :n_votes) do
  def candidate; Candidate.find(candidate_id); end
  def county; County.find(county_id); end
  def fips_int; county.fips_int; end

  def self.all=(v); @all = v; end
  def self.all; @all; end
end
