require_relative './base_view'

require_relative '../models/race_day'

class RaceDayView < BaseView
  attr_reader(:race_day)

  def initialize(race_day)
    @race_day = race_day
  end

  def states; race_day.states.sort_by(&:name); end
  def race_months; RaceDay.all.group_by{ |rd| rd.date.to_s[0...7] }.values; end
  def html_path; "2016/primaries/#{race_day.id}.html"; end
end
