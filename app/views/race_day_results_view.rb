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
      candidate_race_csv: candidate_race_csv,
      candidate_county_race_csv: candidate_county_race_csv,
      candidate_race_subcounty_csv: candidate_race_subcounty_csv,
      county_race_csv: county_race_csv,
      race_subcounty_csv: race_subcounty_csv,
      race_csv: race_csv
    )
  end

  protected

  def candidate_csv
    header = "candidate_id,party_id,n_delegates,n_pledged_delegates\n"
    data = candidates.map{ |c| "#{c.id},#{c.party_id},#{c.n_delegates},#{c.n_pledged_delegates}" }.join("\n")
    header + data
  end

  def candidate_race_csv
    header = "candidate_id,state_code,n_votes,percent_vote,n_delegates,n_pledged_delegates,winner\n"
    data = race_day.candidate_races.map{ |cr| "#{cr.candidate_id},#{cr.state_code},#{cr.n_votes},#{cr.percent_vote},#{cr.n_delegates},#{cr.n_pledged_delegates},#{cr.winner?}" }.join("\n")
    header + data
  end

  def candidate_county_race_csv
    header = "candidate_id,fips_int,n_votes\n"
    data = race_day.candidate_county_races.map{ |cc| "#{cc.candidate_id},#{cc.fips_int},#{cc.n_votes}" }.join("\n")
    header + data
  end

  def candidate_race_subcounty_csv
    header = "candidate_id,geo_id,n_votes\n"
    data = race_day.candidate_race_subcounties.map{ |cs| "#{cs.candidate_id},#{cs.geo_id},#{cs.n_votes}" }.join("\n")
    header + data
  end

  def candidate_subcounty_csv
    header = "candidate_id,geo_id,n_votes\n"
    data = race_day.candidate_subcounties.map{ |cs| "#{cs.candidate_id},#{cs.geo_id},#{cs.n_votes}" }.join("\n")
    header + data
  end

  def county_race_csv
    header = "fips_int,party_id,n_votes,n_precincts_reporting,n_precincts_total\n"
    data = race_day.county_races.map{ |cr| "#{cr.fips_int},#{cr.party_id},#{cr.n_votes},#{cr.n_precincts_reporting},#{cr.n_precincts_total}" }.join("\n")
    header + data
  end

  def race_subcounty_csv
    header = "party_id,geo_id,n_votes,n_precincts_reporting,n_precincts_total\n"
    data = race_day.race_subcounties.map{ |ps| "#{ps.party_id},#{ps.geo_id},#{ps.n_votes},#{ps.n_precincts_reporting},#{ps.n_precincts_total}" }.join("\n")
    header + data
  end

  def race_csv
    header = "party_id,state_code,n_precincts_reporting,n_precincts_total,has_delegate_counts,has_pledged_delegate_counts,last_updated,when_race_happens,n_delegates_with_candidates,n_delegates,n_pledged_delegates_with_candidates,n_pledged_delegates\n"
    data = race_day.races.map{ |r| "#{r.party_id},#{r.state_code},#{r.n_precincts_reporting},#{r.n_precincts_total},#{r.has_delegate_counts?},#{r.has_pledged_delegate_counts?},#{r.last_updated},#{r.when_race_happens},#{r.n_delegates_with_candidates},#{r.n_delegates},#{r.n_pledged_delegates_with_candidates},#{r.n_pledged_delegates}" }.join("\n")
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
