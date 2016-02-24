require_relative './collection_class'

CandidateRaces = CollectionClass.new do
  def find_all_by_candidate_race_day_id(candidate_race_day_id)
    @by_candidate_race_day_id ||= @all.group_by(&:candidate_race_day_id)
    @by_candidate_race_day_id[candidate_race_day_id] || []
  end

  def find_all_by_race_id(race_id)
    @by_race_id ||= @all.group_by(&:race_id)
    @by_race_id[race_id] || []
  end
end
