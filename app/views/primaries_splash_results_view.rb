require_relative './base_view'

require_relative '../models/race_day'

class PrimariesSplashResultsView < BaseView

  def initialize(database)
    super(database)
  end

  def race_day; @race_day ||= database.race_days.find("2016-02-01"); end

  def output_path; "2016/primaries/splash.json"; end

  def build_json
    JSON.dump(
      counties: county_party_objects,
      candidates: candidate_objects,
      when_race_day_happens: race_day.when_race_day_happens
    )
  end

  protected

  def candidate_objects
    data = {
      "Dem" => [],
      "GOP" => []
    }
    race_day.races.each do |race|
      race.candidate_states.each{|cd|
        data[race.party_id].push([cd.candidate_id, cd.n_votes])
      }
    end
    data
  end

  def county_party_objects
    fips = {}
    race_day.county_parties.each do |cp|
      key = cp.fips_int.to_s
      obj = (fips[key] ||= { "n_precincts_total" => 0, "total_n_precincts_reporting" => 0 })
      obj["total_n_precincts_reporting"] += cp.n_precincts_reporting
      obj["n_precincts_total"] += cp.n_precincts_total
      fips[key] = obj
    end
    fips
  end

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
