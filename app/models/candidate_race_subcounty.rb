CandidateRaceSubcounty = RubyImmutableStruct.new(:database, :candidate_id, :race_id, :geo_id, :n_votes) do
  attr_reader(:id)

  def after_initialize
    @id = "#{@candidate_id}-#{@race_id}, #{@geo_id}"
  end
end
