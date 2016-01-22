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
      #parties: parties_csv,
      races: races_csv,
      county_party: county_party_csv
    )
  end

  protected

  def county_party_csv
    header = ["fips_int,party_id,n_precincts_reporting,n_precincts_total,last_updated"]
    data = []
    parties.each do |party|
      race = races.find_by_party_and_state(party, cur_state)
      str = race.county_parties.map{ |cp| "#{cp.fips_int},#{cp.party_id},#{cp.n_precincts_reporting},#{cp.n_precincts_total},#{cp.last_updated}" }.join("\n")
      data.push(str)
    end
    header + data
  end

  def races_csv
    header = ["id,party,state_code,race_type,n_precincts_reporting,n_precincts_total"]
    data = []
    parties.each do |party|
      rd = races.find_by_party_and_state(party, cur_state)
      str = "#{rd.race_day_id},#{rd.party_id},#{rd.state_code},#{rd.race_type},#{rd.n_precincts_reporting},#{rd.n_precincts_total}"
      data.push(str)
    end
    header + data
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
