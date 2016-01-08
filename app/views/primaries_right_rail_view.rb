require 'date'

require_relative './base_view'
require_relative '../models/race_day'

class PrimariesRightRailView < BaseView
  def output_path; '2016/primaries/right-rail.html'; end

  def current_race_day
    next_race_day === Date.today ? next_race_day : nil
  end

  def next_race_day
    all_ids = RaceDay.all.map(&:id)
    today_id = Date.today.to_s
    next_id = all_ids.sort!.find { |id| id >= today_id }
    next_id ? RaceDay.find(next_id) : nil
  end

  def self.generate_all
    self.generate_for_view(PrimariesRightRailView.new)
  end
end
