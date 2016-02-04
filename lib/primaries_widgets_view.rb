require_relative '../app/models/race_day'

module PrimariesWidgetsView

  def race_date_str; @race_date_str = "2016-02-09"; end;

  def race_day; @race_day ||= database.race_days.find(race_date_str); end

  def get_vote_pct(race_id, c_id)
    (candidate_objects_by_race[race_id]["candidates"]["Dem"][c_id] or candidate_objects_by_race[race_id]["candidates"]["GOP"][c_id])[:pct]
  end

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

  #"result" contains all votes, vote percents by candidate by party for each race happening that day
  def candidate_objects_by_race
    result = {}
    race_day.races.each do |race|
      data = (result[race.race_day_id] ||= {"candidates" => {"Dem" => {}, "GOP" => {}}, "total_Dem" => 0, "total_GOP" => 0})
      total_votes = race.candidate_races.map{|cd| cd.n_votes}.inject(0){|sum,x| sum + x }
      data["total_#{race.party_id}"] = total_votes
      race.candidate_races.each{|cd|
        candidate_pct = ((total_votes > 0) ? ((cd.n_votes.to_f / total_votes.to_f) * 100.0).round(1) : 0.0)
        data["candidates"][race.party_id][cd.candidate_id] = {votes: cd.n_votes, pct: candidate_pct}
      }
      leader = race.candidate_races.sort_by(&:n_votes).reverse.first
      data["leader_#{race.party_id}"] = ((leader.n_votes != 0) ? leader.candidate_id : -1)
    end
    result
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

end
