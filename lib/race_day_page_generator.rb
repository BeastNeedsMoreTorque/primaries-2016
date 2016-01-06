require 'haml'

require_relative '../app/models/race_day'
require_relative '../app/views/race_day_view'
require_relative './page_generator'

module RaceDayPageGenerator
  extend PageGenerator

  def self.generate_all
    template = File.read(File.expand_path('../../templates/race-day.html.haml', __FILE__))
    for race_day in RaceDay.all
      self.generate_html(template, RaceDayView.new(race_day))
    end
  end
end
