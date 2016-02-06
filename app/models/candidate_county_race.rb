CandidateCountyRace = RubyImmutableStruct.new(:database, :candidate_id, :fips_int, :race_id, :n_votes) do
  include Comparable

  attr_reader(:id)

  def after_initialize
    @id = "#{@candidate_id}-#{@fips_int}-#{@race_id}"
  end

  def <=>(rhs)
    rhs.n_votes <=> n_votes
  end
end
