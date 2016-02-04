require_relative './base_view'

require_relative '../models/race_day'

class PrimariesSplashResultsView < BaseView

  def initialize(database)
    super(database)
  end

  def race_day; @race_day ||= database.race_days.find("2016-02-01"); end

  def output_path; "2016/primaries/widget-results.json"; end

  def build_json
    JSON.dump(
      precincts: precinct_stats,
      counties: county_party_objects,
      candidates: candidate_objects,
      when_race_day_happens: race_day.when_race_day_happens
    )
  end

  protected

  def precinct_stats
    counties = county_party_objects()
    total_precincts = counties.map{|key, val| val["n_precincts_total"]}.inject(0){|sum,x| sum + x }
    reporting_precincts = counties.map{|key, val| val["total_n_precincts_reporting"]}.inject(0){|sum,x| sum + x }
    finished_counties = counties.values.select{|val| val['n_precincts_total'] == val['total_n_precincts_reporting']}.count
    pct_reporting = (reporting_precincts.to_f / total_precincts.to_f) * 100.0
    reporting_str = ((pct_reporting < 100.0 && pct_reporting > 99.0) ? "99%" : "#{pct_reporting.round}%")
    {
      counties_total: counties.keys.count,
      counties_finished: finished_counties,
      counties_outstanding: finished_counties - counties.keys.count,
      reporting_precincts_sofar: reporting_precincts,
      reporting_precincts_total: total_precincts,
      reporting_precincts_pct_raw: pct_reporting,
      reporting_precincts_pct_str: reporting_str
    }
  end

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
