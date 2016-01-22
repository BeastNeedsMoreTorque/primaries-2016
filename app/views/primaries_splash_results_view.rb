require_relative './base_view'

require_relative '../models/race_day'

class PrimariesSplashResultsView < BaseView

  def initialize(database)
    super(database)
  end

  def cur_state_code; @cur_state_code = 'IA'; end

  def cur_state; @cur_state ||= database.states.find!(cur_state_code); end

  def output_path; "2016/primaries/splash.json"; end

  def build_json
    JSON.dump(
      county_party_objects
    )
  end

  protected

  def county_party_objects
    data = []
    fips = {}
    parties.each{|party|
      race = races.find_by_party_and_state(party, cur_state)
      subkeyGOP = "GOP,#{race.state_code},#{race.race_type}"
      subkeyDem = "Dem,#{race.state_code},#{race.race_type}"
      subkeyThis = "#{race.party_id},#{race.state_code},#{race.race_type}"
      race.county_parties.each{|cp|
        key = cp.fips_int.to_s
        obj = (fips.keys.include? key) ? fips[key] : {"n_precincts_total" => 0, subkeyDem => 0, subkeyGOP => 0, "total_n_precincts_reporting" => 0}
        obj[subkeyThis] += cp.n_precincts_reporting
        obj["total_n_precincts_reporting"] += cp.n_precincts_reporting
        obj["n_precincts_total"] += cp.n_precincts_total
        fips[key] = obj
      }
    }
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
