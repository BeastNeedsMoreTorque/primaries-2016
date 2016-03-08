CandidateRaceSubcounty = RubyImmutableStruct.new(:database, :candidate_id, :race_id, :geo_id, :n_votes) do
  include Comparable

  attr_reader(:id, :party_id, :race_subcounty_id)

  def after_initialize
    @id = "#{@candidate_id}-#{@race_id}, #{@geo_id}"
    @party_id = @race_id[11..13]
    @race_subcounty_id = "#{@race_id}-#{@geo_id}"
  end

  def candidate; database.candidates.find!(@candidate_id); end
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
