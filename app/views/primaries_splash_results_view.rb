require_relative './base_view'

require_relative '../models/race_day'

class PrimariesSplashResultsView < BaseView
  attr_reader(:race_day)

  def initialize(database, race_day)
    super(database)
    @race_day = race_day
  end

  def output_path; "2016/primaries/splash.json"; end

  def build_json
    JSON.dump(
      county_party: county_party_csv
    )
  end

  protected

  def county_party_csv
    header = "fips_int,party_id,n_precincts_reporting,n_precincts_total,last_updated\n"
    data = race_day.county_parties.map{ |cp| "#{cp.fips_int},#{cp.party_id},#{cp.n_precincts_reporting},#{cp.n_precincts_total},#{cp.last_updated}" }.join("\n")
    header + data
  end

  def self.generate_all(database)
    race_day = database.race_days.first
    generate_for_view(PrimariesSplashResultsView.new(database, race_day))
  end

  protected

  def self.generate_for_view(view)
    path = "#{Paths.Dist}/#{view.output_path}"
    $logger.debug("Generating #{path}")
    output = view.build_json
    self.write_contents(path, output)
  end
end
