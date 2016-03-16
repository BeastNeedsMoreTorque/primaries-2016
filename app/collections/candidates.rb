require_relative './collection_class'

Candidates = CollectionClass.new do
  def find_all_by_party_id(party_id)
    @by_party_id ||= all.group_by(&:party_id)
    @by_party_id[party_id] || []
  end
end
