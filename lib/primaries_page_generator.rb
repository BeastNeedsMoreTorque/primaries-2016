require 'haml'

require_relative '../app/models/race'
require_relative '../app/views/primary_view'
require_relative './page_generator'

module PrimariesPageGenerator
  extend PageGenerator
  @template = File.read(File.expand_path('../../templates/primary.html.haml', __FILE__))

  def self.generate_all
    for race in Race.all
      self.generate_for_race(race)
    end
  end

  # Generate all static files for the given Race.
  #
  # Generates an HTML file and a JSON file.
  def self.generate_for_race(race)
    self.generate_html(@template, PrimaryView.new(race))
  end
end
