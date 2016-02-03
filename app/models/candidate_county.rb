CandidateCounty = RubyImmutableStruct.new(:database, :party_id, :candidate_id, :fips_int, :n_votes) do
  attr_reader(:id)

  def after_initialize
    @id = "#{@candidate_id}-#{@fips_int}"
  end
end
