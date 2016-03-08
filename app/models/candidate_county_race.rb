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

  def <=>(rhs)
    if (x = race_id <=> rhs.race_id) != 0
      x
    elsif (x = geo_id <=> rhs.geo_id) != 0
      x
    else
      rhs.n_votes <=> n_votes
    end
  end
end
