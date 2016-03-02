CandidateCountyRace = RubyImmutableStruct.new(:database, :candidate_id, :fips_int, :race_id, :n_votes) do
  include Comparable

  attr_reader(:id)

  def after_initialize
    @id = "#{@candidate_id}-#{@fips_int}-#{@race_id}"
  end

  def geo_id; fips_int; end

  def <=>(rhs)
    if (x = id <=> rhs.id) != 0
      x
    else
      rhs.n_votes <=> n_votes
    end
  end
end
