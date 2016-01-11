require_relative './collection_class'
require_relative '../models/race'

Races = CollectionClass.new('races', 'race', Race) do
  # Returns a Race ... or nil if there won't be one.
  #
  # (Colorado Republicans  won't vote for a presidential nominee in 2016.)
  def find_by_party_and_state(party, state)
    @by_party_and_state ||= map{ |r| [ "#{r.party.id}-#{r.state.code}", r ] }.to_h
    @by_party_and_state["#{party.id}-#{state.code}"]
  end
end
