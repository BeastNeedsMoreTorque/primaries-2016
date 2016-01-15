require_relative './base_view'
require_relative '../../lib/primaries_embed_view'
require 'date'

class PrimariesRightRailView < BaseView
  include PrimariesEmbedView

  def output_path; '2016/primaries/right-rail.html'; end

  def state_iowa; @state_iowa = database.states.find!('IA'); end

  def sort_iowa_data(party, state)
    race = races.find_by_party_and_state(party, state)
    cd_states = race.candidate_states
    cd_states = cd_states.select {|cd_s| cd_s.poll_percent != nil}
    cd_states_sorted = cd_states.sort_by do |to_sort|
      to_sort.poll_percent
    end
    return cd_states_sorted.reverse
  end

  def following_races(date)
    date_s = date.to_s
    database.race_days.select { |r| r.id > date_s }
  end

  def previous_races(date)
    date_s = date.to_s
    database.race_days.select { |r| r.id < date_s }
  end

  def dem_states_string(coded_party)
    state_string = ""
    if !coded_party.nil?
      coded_party.each do |state|
        state_string += state.to_s + "(D.) "
      end
    end
    return state_string
  end

  def gop_states_string(coded_party)
    state_string = ""
    if !coded_party.nil?
      coded_party.each do |state|
        state_string += state.to_s + "(R.) "
      end
    end
    return state_string
  end

  def self.generate_all(database)
    self.generate_for_view(PrimariesRightRailView.new(database))
  end
end
