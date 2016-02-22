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
      races: races_h,
      when_race_day_happens: race_day.when_race_day_happens
    )
  end

  protected

  def self.generate_all(database)
    generate_for_view(PrimariesSplashResultsView.new(database))
  end

  def self.generate_for_view(view)
    path = "#{Paths.Dist}/#{view.output_path}"
    $logger.debug("Generating #{path}")
    output = view.build_json
    self.write_contents(path, output)
  end

  private

  # [ { "id" -> "race-day ID", "candidates" -> [JSON], "geos" -> [JSON], "precincts_reporting_percent" -> "94%" } }
  def races_h
    race_day.races.map { |race| race_h(race) }
  end

  def race_h(race)
    {
      id: race.id,
      when_race_happens: race.when_race_happens,
      candidates: race.candidate_races.map { |cr| candidate_race_h(cr) },
      geos: race_geos_h(race),
      precincts_reporting_percent_s: race.pct_precincts_reporting
    }
  end

  # { last_name -> "Foo", n_votes -> 1234, percent_vote -> 23.3, winner -> false }
  def candidate_race_h(candidate_race)
    {
      id: candidate_race.candidate_id,
      last_name: candidate_race.candidate_last_name,
      n_votes: candidate_race.n_votes,
      percent_vote: candidate_race.percent_vote,
      leader: candidate_race.leader?,
      winner: candidate_race.winner?
    }
  end

  # Turns an Array of CandidateRaceSubcounty or CandidateCountyRace objects
  # into an Array of [ geo_id, candidate_id ] pairs for all geos with precincts
  # reporting.
  def candidate_geo_races_to_leader_a(candidate_geo_races)
    geo_id_stats = {} # { id -> { leader_id, leader_n_votes } }

    for cgr in candidate_geo_races
      geo_id = cgr.geo_id
      n_votes = cgr.n_votes

      if n_votes > 0 && (!geo_id_stats.include?(geo_id) || n_votes > geo_id_stats[geo_id][:leader_n_votes])
        geo_id_stats[geo_id] = {
          leader_id: cgr.candidate_id,
          leader_n_votes: n_votes
        }
      end
    end

    geo_id_stats.map { |geo_id, data| [ geo_id, data[:leader_id] ] }
  end

  # { geo_id -> leader candidate_id or nil }
  def race_geos_h(race)
    arr = candidate_geo_races_to_leader_a(race.candidate_county_races) + candidate_geo_races_to_leader_a(race.candidate_race_subcounties)
    arr.to_h
  end

  # { race_id -> { geo_id -> leader_candidate_id } }
  def geos
    ret = {}

    race_day.race_subcounties.each do |rs|
      geo_id = rs.geo_id
      party_id = rs.party_id

      geo_obj = ret[geo_id] ||= {
        n_precincts_reporting: 0,
        n_precincts_total: 0,
        'Dem' => { n_precincts_reporting: 0, n_precincts_total: 0, leader: { id: nil, n_votes: 0 } },
        'GOP' => { n_precincts_reporting: 0, n_precincts_total: 0, leader: { id: nil, n_votes: 0 } }
      }

      geo_obj[:n_precincts_reporting] += rs.n_precincts_reporting
      geo_obj[:n_precincts_total] += rs.n_precincts_total
      geo_obj[party_id][:n_precincts_reporting] += rs.n_precincts_reporting
      geo_obj[party_id][:n_precincts_total] += rs.n_precincts_total
    end

    race_day.candidate_race_subcounties.each do |crs|
      geo_id = crs.geo_id
      party_id = crs.party_id

      leader_obj = ret[geo_id][party_id][:leader]
      if crs.n_votes > leader_obj[:n_votes]
        leader_obj[:id] = crs.candidate_id
        leader_obj[:n_votes] = crs.n_votes
      end
    end

    ret
  end
end
