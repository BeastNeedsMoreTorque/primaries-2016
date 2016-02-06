require_relative './collection_class'

Races = CollectionClass.new do
  def find_all_by_party_state_id(party_state_id)
    @by_party_state_id = all.group_by(&:party_state_id)
    @by_party_state_id[party_state_id] || []
  end
end
