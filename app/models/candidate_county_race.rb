CandidateCountyRace = RubyImmutableStruct.new(:database, :candidate_id, :fips_int, :race_id, :n_votes) do
  include Comparable

  attr_reader(:id)

  def after_initialize
    @id = "#{@candidate_id}-#{@fips_int}-#{@race_id}"
  end

  def geo_id; fips_int; end

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
