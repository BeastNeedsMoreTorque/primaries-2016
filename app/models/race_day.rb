require 'date'
require 'set'

RaceDay = Struct.new(:database, :id, :races_codified) do
  def date; @date ||= Date.parse(id); end
  def disabled?; database.last_date && date > database.last_date; end
  def enabled?; !disabled?; end

  # States that have one or more races on this day
  def states
    @states ||= races.map(&:state).uniq.sort_by(&:name)
  end

  # Returns an Array of [ State, [ [Party, Race_or_nil, other_Races] ] ]
  #
  # Usage:
  #
  #   race_day.state_party_races do |state, party_races|
  #     party_races.each do |party, race_day_race, other_races |
  #       ...
  #     end
  #   end
  def state_party_races
    @state_party_races ||= states
      .map do |state|
        [
          state,
          database.parties.map do |party|
            [
              party,
              database.races.find_by_party_id_race_day_id_state_code(party.id, id, state.code),
              database.races.find_all_by_party_id_state_code(party.id, state.code)
                .reject { |r| r.race_day_id == id }
            ]
          end
        ]
      end
  end

  # "past" when all races have finished reporting
  # "present" if any race is reporting
  # "future" if no races are reporting
  def when_race_day_happens
    tenses = races.map(&:when_race_happens)

    if tenses.include? "present"
      "present"
    elsif tenses.first == "past"
      "past"
    else
      "future"
    end
  end

  def races
    @races ||= database.races
      .select{ |r| r.race_day_id == id }
      .sort_by! { |r| "#{r.state_name} #{r.party_name}" }
  end

  def states_for_party(party)
    @states_for_party ||= {}
    @states_for_party[party.id] ||= races.select{ |r| r.party_id == party.id }.map(&:state)
  end

  def candidate_states
    @candidate_states ||= races.flat_map(&:candidate_states)
  end

  def candidate_counties
    @candidate_counties ||= races.flat_map(&:candidate_counties)
  end

  def county_parties
    @county_parties ||= races.flat_map(&:county_parties)
  end
end
