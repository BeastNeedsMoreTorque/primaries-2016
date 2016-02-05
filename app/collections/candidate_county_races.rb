require_relative './collection_class'

CandidateCountyRaces = CollectionClass.new do
  def find_all_by_race_id(race_id)
    @by_race_id ||= all.group_by { |ccr| ccr.race_id }
    @by_race_id[race_id] || []
  end
end
