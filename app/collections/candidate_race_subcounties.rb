require_relative './collection_class'

CandidateRaceSubcounties = CollectionClass.new do
  def find_all_by_race_id(race_id)
    @by_race_id ||= all.group_by(&:race_id)
    @by_race_id[race_id] || []
  end

  def find_all_by_race_subcounty_id(race_subcounty_id)
    @by_race_subcounty_id ||= all.group_by(&:race_subcounty_id)
    @by_race_subcounty_id[race_subcounty_id] || []
  end
end
