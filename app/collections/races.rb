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

  def sorted_by_state_name_and_race_day
    all.sort do |a,b|
      c1 = a.state_name.<=>(b.state_name)
      if c1 != 0
        c1
      else
        c2 = a.race_day_id.<=>(b.race_day_id)
        if c2 != 0
          c2
        else
          a.party_name.<=>(b.party_name)
        end
      end
    end
  end
end
