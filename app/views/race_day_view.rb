require_relative './base_view'

require_relative '../models/race_day'

class RaceDayView < BaseView
  attr_reader(:race_day)

  def initialize(race_day); @race_day = race_day; end

  def output_path; "2016/primaries/#{race_day.id}.html"; end

  def states; race_day.states.sort_by(&:name); end

  def self.generate_all
    RaceDay.all.each do |race_day|
      self.generate_for_view(RaceDayView.new(race_day))
    end
  end
end
