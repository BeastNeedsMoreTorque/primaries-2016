require_relative './collection_class'

CandidateCountyRaces = CollectionClass.new do
  def find_all_by_race_id(race_id)
    @by_race_id ||= all.group_by(&:race_id)
    @by_race_id[race_id] || []
  end

  def find_all_by_county_race_id(county_race_id)
    @by_county_race_id ||= all.group_by(&:county_race_id)
    @by_county_race_id[county_race_id] || []
  end
end
