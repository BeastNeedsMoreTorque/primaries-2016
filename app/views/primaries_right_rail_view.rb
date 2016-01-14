require_relative './base_view'
require_relative '../../lib/primaries_embed_view'

class PrimariesRightRailView < BaseView
  include PrimariesEmbedView

  def output_path; '2016/primaries/right-rail.html'; end

  def dem_candidates; database.candidates.select{ |cd| cd.party_id == 'GOP'}; end
  def gop_candidates; database.candidates.select{ |cd| cd.party_id == 'GOP'}; end
  def state_iowa; database.states.select{ |s| s.code == 'IA' }; end

  def following_races(date)
    next_races = []
    all_ids = database.race_days.all.map(&:id)
    next_ids = all_ids.sort!.find_all { |id| id > date }
    next_ids.each do |id|
      next_races << database.race_days.find(id)
    end
    next_races
  end

  def dem_states_string(coded_party)
    state_string = ""
    if !coded_party.nil?
      coded_party.each do |state|
        state_string += state.to_s + " "
      end
    end
    return state_string
  end

  def gop_states_string(coded_party)
    state_string = ""
    if !coded_party.nil?
      coded_party.each do |state|
        state_string += state.to_s + " "
      end
    end
    return state_string
  end

  def self.generate_all(database)
    self.generate_for_view(PrimariesRightRailView.new(database))
  end
end
