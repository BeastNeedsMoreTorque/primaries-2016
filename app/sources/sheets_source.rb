require 'time'

# Loads from Google Sheets
#
# Provides:
#
# * candidates: id, party_id, name, last_name, dropped_out_date_or_nil, in_horse_race
# * parties: id, name, adjective
# * party_states: party_id, state_code, n_delegates, n_unpledged_delegates
# * races: race_day_id, party_id, state_code, race_type, ap_says_its_over, :huffpost_override_winner_last_name
# * race_days: id
# * states: fips_int, code, abbreviation, name
class SheetsSource
  Candidate = RubyImmutableStruct.new(:id, :party_id, :full_name, :last_name, :dropped_out_date_or_nil, :in_horse_race)

  Party = RubyImmutableStruct.new(:id, :name, :adjective)

  PartyState = RubyImmutableStruct.new(:party_id, :state_code, :n_delegates, :n_unpledged_delegates) do
    attr_reader(:id)

    def after_initialize
      @id = "#{@party_id}-#{@state_code}"
    end
  end

  Race = RubyImmutableStruct.new(
    :race_day_id,
    :party_id,
    :state_code,
    :race_type,
    :expect_results_time,
    :ap_says_its_over,
    :huffpost_override_winner_last_name,
    :n_votes_th,
    :n_votes_tooltip_th,
    :n_votes_footnote
  ) do
    attr_reader(:id)
    attr_reader(:party_state_id)

    def after_initialize
      @id = "#{@race_day_id}-#{@party_id}-#{@state_code}"
      @party_state_id = "#{@party_id}-#{@state_code}"
    end
  end

  RaceDay = RubyImmutableStruct.new(:id)

  State = RubyImmutableStruct.new(:fips_int, :state_code, :abbreviation, :name)

  attr_reader(:candidates, :parties, :party_states, :races, :race_days, :states)

  def initialize(candidates_tsv, parties_tsv, races_tsv, race_days_tsv, states_tsv)
    @candidates = candidates_tsv.split(/\r?\n/)[1..-1].map do |line|
      id, party_id, name, last_name, dropped_out_or_empty, in_horse_race_s = line.split(/\t/)
      dropped_out_date_or_nil = dropped_out_or_empty == '' ? nil : Date.parse(dropped_out_or_empty)
      in_horse_race = in_horse_race_s == 'TRUE'
      Candidate.new(id, party_id, name, last_name, dropped_out_date_or_nil, in_horse_race)
    end

    @parties = parties_tsv.split(/\r?\n/)[1..-1].map do |line|
      id, name, adjective = line.split(/\t/)
      Party.new(id, name, adjective)
    end

    @races = races_tsv.split(/\r?\n/)[1..-1].map do |line|
      arr = line.split(/\t/)
        .map! { |x| x.empty? ? nil : x }
      arr[4] = Time.parse(arr[4]) if arr[4] # expect_results_time
      arr[5] = (arr[5] == 'TRUE')           # ap_says_its_over

      Race.new(*arr)
    end

    @race_days = race_days_tsv.split(/\r?\n/)[1..-1].map do |line|
      RaceDay.new(line)
    end

    @states = []
    @party_states = []
    states_tsv.split(/\r?\n/)[1..-1].each do |line|
      fips_int_s, state_code, abbreviation, name, n_dem_delegates_s, n_dem_unpledged_delegates_s, n_gop_delegates_s, n_gop_unpledged_delegates_s = line.split(/\t/)
      fips_int = fips_int_s.to_i
      n_dem_delegates = n_dem_delegates_s.to_i
      n_dem_unpledged_delegates = n_dem_unpledged_delegates_s.to_i
      n_gop_delegates = n_gop_delegates_s.to_i
      n_gop_unpledged_delegates = n_gop_unpledged_delegates_s.to_i

      @states << State.new(fips_int, state_code, abbreviation, name)
      @party_states << PartyState.new('Dem', state_code, n_dem_delegates, n_dem_unpledged_delegates) if n_dem_delegates > 0
      @party_states << PartyState.new('GOP', state_code, n_gop_delegates, n_gop_unpledged_delegates) if n_gop_delegates > 0
    end
  end
end
