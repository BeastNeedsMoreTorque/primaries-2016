CandidateCountyRace = RubyImmutableStruct.new(:database, :candidate_id, :fips_int, :race_id, :n_votes) do
  include Comparable

  attr_reader(:id, :county_race_id)

  def after_initialize
    @id = "#{@candidate_id}-#{@fips_int}-#{@race_id}"
    @county_race_id = "#{@fips_int}-#{@race_id}"
  end

  def geo_id; fips_int; end

  def candidate; database.candidates.find!(candidate_id); end
  def candidate_slug; candidate.slug; end
  def get_all_sibling_candidate_county_races; database.candidate_county_races.select{|ccr| ccr.fips_int == fips_int and ccr.candidate.party_id == candidate.party_id}; end
  def total_geo_votes_candidate_party; get_all_sibling_candidate_county_races.map{|ccr| ccr.n_votes}.inject(0){|sum,x| sum + x }; end
  def candidate_percent_votes; ((n_votes.to_f/total_geo_votes_candidate_party.to_f) * 100.0).round(1); end
  def get_percent_votes_by_candidate
    get_all_sibling_candidate_county_races.sort_by{|ccr| ccr.candidate.name}.map{|ccr| {ccr.candidate.name => ccr.candidate_percent_votes}}
  end


  def <=>(rhs)
    if (x = race_id <=> rhs.race_id) != 0
      x
    elsif (x = fips_int <=> rhs.fips_int) != 0
      x
    elsif (x = rhs.n_votes <=> n_votes) != 0
      x
    else
      candidate_id <=> rhs.candidate_id
    end
  end
end
