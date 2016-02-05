require_relative './collection_class'

RaceSubcounties = CollectionClass.new do
  def find_all_by_race_id(race_id)
    @by_race_id ||= all.group_by(&:race_id)
    @by_race_id[race_id] || []
  end
end
