require_relative './base_view'

require_relative '../models/race_day'
require_relative '../../lib/primaries_widgets_view'

class PrimariesSplashResultsView < BaseView
  include PrimariesWidgetsView

  def initialize(database)
    super(database)
  end

  def output_path; "2016/primaries/widget-results.json"; end

  def build_json
    JSON.dump(
      precincts: precinct_stats,
      counties: county_party_objects,
      candidates: candidate_objects_by_race.first.last,#TODO: look at all races multi-race days
      when_race_day_happens: race_day.when_race_day_happens
    )
  end

  protected

  def self.generate_all(database)
    generate_for_view(PrimariesSplashResultsView.new(database))
  end

  protected

  def self.generate_for_view(view)
    path = "#{Paths.Dist}/#{view.output_path}"
    $logger.debug("Generating #{path}")
    output = view.build_json
    self.write_contents(path, output)
  end
end
