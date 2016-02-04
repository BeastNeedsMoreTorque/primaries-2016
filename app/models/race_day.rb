require 'date'
require 'set'

RaceDay = RubyImmutableStruct.new(:database_or_nil, :id, :enabled, :title, :body, :tweet, :pubbed_dt, :updated_dt_or_nil) do
  attr_reader(:date)

  # All Races on this day
  attr_reader(:races)

  # States that have one or more races on this day
  attr_reader(:states)

  # Array of [ State, [ [Party, Race_or_nil, other_Races] ] ]
  #
  # Usage:
  #
  #   race_day.state_party_races do |state, party_races|
  #     party_races.each do |party, race_day_race, other_races |
  #       ...
  #     end
  #   end
  attr_reader(:state_party_races)

  attr_reader(:candidate_races, :candidate_states, :candidate_counties, :county_parties)

  def after_initialize
    @date = Date.parse(id)

    if database_or_nil
      @races = database_or_nil.races
        .select{ |r| r.race_day_id == id }
        .sort_by! { |r| "#{r.state_name} #{r.party_name}" }

      @states = races.map(&:state).uniq.sort_by(&:name)

      @state_party_races = states.map do |state|
        [
          state,
          database_or_nil.parties.map do |party|
            [
              party,
              database_or_nil.races.find_by_party_id_race_day_id_state_code(party.id, id, state.code),
              database_or_nil.races.find_all_by_party_id_state_code(party.id, state.code)
                .reject { |r| r.race_day_id == id }
            ]
          end
        ]
      end

      @candidate_races = races.flat_map(&:candidate_races)
      @candidate_states = races.flat_map(&:candidate_states)
      @candidate_counties = races.flat_map(&:candidate_counties)
      @county_parties = races.flat_map(&:county_parties)
    end
  end

  def disabled?; !@enabled; end
  def enabled?; @enabled; end

  # "past" when all races have finished reporting
  # "present" if any race is reporting
  # "future" if no races are reporting
  def when_race_day_happens
    tenses = races.map(&:when_race_happens)
    return "past"
    if tenses.include? "present"
      "present"
    elsif tenses.first == "past"
      "past"
    else
      "future"
    end
  end
end
