require_relative './collection_class'

PartyRaceDays = CollectionClass.new do
  def find_all_by_race_day_id(race_day_id)
    @by_race_day_id ||= all.group_by(&:race_day_id)
    @by_race_day_id[race_day_id] || []
  end
end
