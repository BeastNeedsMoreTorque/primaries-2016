require_relative './source'

require 'time'

# Loads from Google Sheets
#
# Provides:
#
# * candidates: id, party_id, name, last_name, dropped_out_date_or_nil
# * parties: id, name, adjective
# * party_states: party_id, state_code, n_delegates
# * races: race_day_id, party_id, state_code, race_type, ap_says_its_over, :huffpost_override_winner_last_name
# * race_days: id
# * states: fips_int, code, abbreviation, name
class SheetsSource < Source
  Candidate = RubyImmutableStruct.new(:id, :party_id, :full_name, :last_name, :dropped_out_date_or_nil)

  Party = RubyImmutableStruct.new(:id, :name, :adjective)

  PartyState = RubyImmutableStruct.new(:party_id, :state_code, :n_delegates) do
    attr_reader(:id)

    def after_initialize
      @id = "#{@party_id}-#{@state_code}"
    end
  end

  Race = RubyImmutableStruct.new(:race_day_id, :party_id, :state_code, :race_type, :expect_results_time, :ap_says_its_over, :huffpost_override_winner_last_name) do
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
      id, party_id, name, last_name, dropped_out_or_empty = line.split(/\t/)
      dropped_out_date_or_nil = dropped_out_or_empty ? Date.parse(dropped_out_or_empty) : nil
      Candidate.new(id, party_id, name, last_name, dropped_out_date_or_nil)
    end

    @parties = parties_tsv.split(/\r?\n/)[1..-1].map do |line|
      id, name, adjective = line.split(/\t/)
      Party.new(id, name, adjective)
    end

    @races = races_tsv.split(/\r?\n/)[1..-1].map do |line|
      date_s, party_id, state_code, race_type, expect_results_ISO8601_UTC, ap_says_its_over, huffpost_override_winner_last_name = line.split(/\t/)
      expect_results_time = expect_results_ISO8601_UTC && Time.parse(expect_results_ISO8601_UTC) || nil
      Race.new(date_s, party_id, state_code, race_type, expect_results_time, ap_says_its_over == 'TRUE', huffpost_override_winner_last_name || nil)
    end

    @race_days = race_days_tsv.split(/\r?\n/)[1..-1].map do |line|
      RaceDay.new(line)
    end

    @states = []
    @party_states = []
    states_tsv.split(/\r?\n/)[1..-1].each do |line|
      fips_int_s, state_code, abbreviation, name, n_dem_delegates_s, n_gop_delegates_s = line.split(/\t/)
      fips_int = fips_int_s.to_i
      n_dem_delegates = n_dem_delegates_s.to_i
      n_gop_delegates = n_gop_delegates_s.to_i

      @states << State.new(fips_int, state_code, abbreviation, name)
      @party_states << PartyState.new('Dem', state_code, n_dem_delegates) if n_dem_delegates > 0
      @party_states << PartyState.new('GOP', state_code, n_gop_delegates) if n_gop_delegates > 0
    end
  end
end
