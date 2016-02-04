require_relative './collection_class'
require_relative '../models/candidate_race'

CandidateRaces = CollectionClass.new('candidate_races', 'candidate_race', CandidateRace) do
  def find_all_by_race_id(race_id)
    @by_race_id ||= @all.group_by(&:race_id)
    @by_race_id[race_id] || []
  end
end
