require_relative './base_view'

require_relative '../models/race_day'

class RaceDayResultsView < BaseView
  attr_reader(:race_day)

  def initialize(database, race_day)
    super(database)
    @race_day = race_day
  end

  def output_path; "2016/primaries/#{race_day.id}.json"; end

  def build_json
    JSON.dump(
      candidate_csv: candidate_csv,
      candidate_state_csv: candidate_state_csv,
      candidate_county_csv: candidate_county_csv,
      county_party_csv: county_party_csv,
      race_csv: race_csv
    )
  end

  protected

  def candidate_csv
    header = "candidate_id,party_id,n_delegates,n_unpledged_delegates\n"
    data = candidates.map{ |c| "#{c.id},#{c.party_id},#{c.n_delegates},#{c.n_unpledged_delegates}" }.join("\n")
    header + data
  end

  def candidate_state_csv
    header = "candidate_id,state_code,n_votes,n_delegates\n"
    data = race_day.candidate_states.map{ |cs| "#{cs.candidate_id},#{cs.state_code},#{cs.n_votes},#{cs.n_delegates}" }.join("\n")
    header + data
  end

  def candidate_county_csv
    header = "candidate_id,fips_int,n_votes\n"
    data = race_day.candidate_counties.map{ |cc| "#{cc.candidate_id},#{cc.fips_int},#{cc.n_votes}" }.join("\n")
    header + data
  end

  def county_party_csv
    header = "fips_int,party_id,n_precincts_reporting,n_precincts_total,last_updated\n"
    data = race_day.county_parties.map{ |cp| "#{cp.fips_int},#{cp.party_id},#{cp.n_precincts_reporting},#{cp.n_precincts_total},#{cp.last_updated}" }.join("\n")
    header + data
  end

  def race_csv
    header = "party_id,state_code,n_precincts_reporting,n_precincts_total,last_updated\n"
    data = race_day.races.map{ |r| "#{r.party_id},#{r.state_code},#{r.n_precincts_reporting},#{r.n_precincts_total},#{r.last_updated}" }.join("\n")
    header + data
  end

  def self.generate_all(database)
    for race_day in database.race_days.select(&:enabled?)
      generate_for_view(RaceDayResultsView.new(database, race_day))
    end
  end

  protected

  def self.generate_for_view(view)
    path = "#{Paths.Dist}/#{view.output_path}"
    $logger.debug("Generating #{path}")
    output = view.build_json
    self.write_contents(path, output)
  end
end
