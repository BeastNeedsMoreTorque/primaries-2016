CandidateCounty = Struct.new(:database, :candidate_id, :county_id, :n_votes) do
  def candidate; database.candidates.find(candidate_id); end
  def county; database.counties.find(county_id); end
  def fips_int; county.fips_int; end
end
