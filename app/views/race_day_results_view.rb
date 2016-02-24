require_relative './base_view'

require_relative '../models/race_day'
require_relative '../helpers/dot_group_helper'

class RaceDayResultsView < BaseView
  include DotGroupHelper

  attr_reader(:race_day)

  def initialize(database, race_day)
    super(database)
    @race_day = race_day
  end

  def output_path; "2016/primaries/#{race_day.id}.json"; end

  def build_json
    JSON.dump(
      candidate_csv: candidate_csv.strip,
      candidate_race_csv: candidate_race_csv.strip,
      candidate_county_race_csv: candidate_county_race_csv.strip,
      candidate_race_subcounty_csv: candidate_race_subcounty_csv.strip,
      county_race_csv: county_race_csv.strip,
      party_csv: party_csv.strip,
      race_subcounty_csv: race_subcounty_csv.strip,
      race_csv: race_csv.strip
    )
  end

  protected

  def candidate_csv
    header = "candidate_id,party_id,last_name,n_delegates,n_pledged_delegates,n_delegates_in_race_day,n_pledged_delegates_in_race_day,delegate_dot_groups,pledged_delegate_dot_groups\n"
    data = candidates.map{ |c| "#{c.id},#{c.party_id},#{c.last_name},#{c.n_delegates},#{c.n_pledged_delegates},#{n_delegates(c, :n_delegates)},#{n_delegates(c, :n_pledged_delegates)},#{encode_delegate_dot_groups(c, :n_delegates)},#{encode_delegate_dot_groups(c, :n_pledged_delegates)}" }.join("\n")
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

  def party_csv
    header = "id,n_delegates_up_for_grabs,n_pledged_delegates_up_for_grabs,delegate_dots_up_for_grabs,pledged_delegate_dots_up_for_grabs\n"
    data = database.party_race_days.find_all_by_race_day_id(race_day.id).map do |prd|
      "#{prd.party_id},#{prd.n_delegates_up_for_grabs},#{prd.n_pledged_delegates_up_for_grabs},#{encode_up_for_grabs_delegate_dot_groups(prd, :n_delegates)},#{encode_up_for_grabs_delegate_dot_groups(prd, :n_pledged_delegates)}"
    end.join("\n")
    header + data
  end

  def race_subcounty_csv
    header = "party_id,geo_id,n_votes,n_precincts_reporting,n_precincts_total\n"
    data = race_day.race_subcounties.map{ |ps| "#{ps.party_id},#{ps.geo_id},#{ps.n_votes},#{ps.n_precincts_reporting},#{ps.n_precincts_total}" }.join("\n")
    header + data
  end

  def race_csv
    header = "party_id,state_code,n_precincts_reporting,n_precincts_total,has_delegate_counts,has_pledged_delegate_counts,last_updated,when_race_happens,n_delegates_with_candidates,n_delegates,n_pledged_delegates_with_candidates,n_pledged_delegates,delegate_dots,pledged_delegate_dots\n"
    data = race_day.races.map{ |r| "#{r.party_id},#{r.state_code},#{r.n_precincts_reporting},#{r.n_precincts_total},#{r.has_delegate_counts?},#{r.has_pledged_delegate_counts?},#{r.last_updated},#{r.when_race_happens},#{r.n_delegates_with_candidates},#{r.n_delegates},#{r.n_pledged_delegates_with_candidates},#{r.n_pledged_delegates},#{encode_race_delegate_dots(r, :n_delegates)},#{encode_race_delegate_dots(r, :n_pledged_delegates)}" }.join("\n")
    header + data
  end

  def self.generate_all(database)
    for race_day in database.race_days.select(&:enabled?)
      generate_for_view(RaceDayResultsView.new(database, race_day))
    end
  end

  # Number of delegates at stake in this race day's states for this candidate
  def n_delegates(candidate, method)
    database.candidate_races.find_all_by_candidate_race_day_id("#{candidate.id}-#{race_day.id}").map(&method).reduce(0, :+)
  end

  def encode_race_delegate_dots(race, method)
    group_dot_subgroups([
      DotSubgroup.new('with-candidates', race.send("#{method}_with_candidates")),
      DotSubgroup.new('without-candidates', race.send("#{method}_without_candidates"))
    ]).to_s
  end

  def encode_delegate_dot_groups(candidate, method)
    candidate_races = database.candidate_races.find_all_by_candidate_race_day_id(candidate.id + '-' + race_day.id)

    dot_subgroups = candidate_races.map { |cr| DotSubgroup.new(cr.state_code, cr.send(method)) }
    group_dot_subgroups(dot_subgroups).to_s
  end

  def encode_up_for_grabs_delegate_dot_groups(party_race_day, method)
    dot_subgroups = party_race_day.candidate_states.group_by(&:party_state).map do |party_state, candidate_states|
      state_code = party_state.state_code
      n_dots = party_state.send(method) - candidate_states.map(&method).reduce(0, :+)

      DotSubgroup.new(state_code, n_dots)
    end

    group_dot_subgroups(dot_subgroups).to_s
  end

  protected

  def self.generate_for_view(view)
    path = "#{Paths.Dist}/#{view.output_path}"
    $logger.debug("Generating #{path}")
    output = view.build_json
    self.write_contents(path, output)
  end
end
