require 'date'

require_relative '../app/models/race_day'

module PrimariesEmbedView
  def current_race_day
    next_race_day === Date.today ? next_race_day : nil
  end

  def next_race_day
    all_ids = RaceDay.all.map(&:id)
    today_id = Date.today.to_s
    next_id = all_ids.sort!.find { |id| id >= today_id }
    next_id ? RaceDay.find(next_id) : nil
  end
end
