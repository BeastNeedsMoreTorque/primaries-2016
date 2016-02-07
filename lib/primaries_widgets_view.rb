require_relative '../app/models/race_day'

module PrimariesWidgetsView

  def race_date_str; @race_date_str = "2016-02-09"; end;

  def race_day; @race_day ||= database.race_days.find(race_date_str); end

  def get_vote_pct(race_id, c_id)
    (candidate_objects_by_race[race_id]["candidates"]["Dem"][c_id] or candidate_objects_by_race[race_id]["candidates"]["GOP"][c_id])[:pct]
  end

  def precinct_stats
    geos = geos_party_objects().values
    reporting_precincts = geos.map{|g| g[:n_precincts_reporting]}.reject(&:nil?).reduce(0, :+)
    total_precincts = geos.map{|g| g[:n_precincts_total]}.reject(&:nil?).reduce(0, :+)
    finished_geos = geos.select{|val| val[:n_precincts_total] == val[:n_precincts_reporting]}.count
    unfinished_geos = geos.select{|val| val[:n_precincts_reporting] > 0 and val[:n_precincts_reporting] < val[:n_precincts_total]}.count
    noresults = geos.select{|val| val[:n_precincts_reporting] == 0}.count
    reporting_str = if total_precincts.nil? || total_precincts == 0
      'N/A'
    elsif reporting_precincts == total_precincts
      '100%'
    else
      pct_reporting = (reporting_precincts.to_f / total_precincts.to_f) * 100.0
      if pct_reporting > 99
        '99%'
      else
        "#{pct_reporting.round}%"
      end
    end

    {
      geos_total: geos.count,
      geos_finished: finished_geos,
      geos_unfinished: unfinished_geos,
      geos_noresults: noresults,
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
      data = (result[race.race_day_id] ||= {:candidates => {:Dem => [], :GOP => []}})
      race.candidate_races.each{|cd|
        candidate_pct = cd.percent_vote
        candidate_votes = cd.n_votes
        data[:candidates][race.party_id.to_sym].push( {votes: candidate_votes, pct: candidate_pct, name: cd.candidate.name} )
      }
    end
    result
  end

  def geos_party_objects
    ids = {}
    #race_day.county_races.each for days other than NH, also should have a dict for each race
    race_day.race_subcounties.each do |cp|
      key = cp.geo_id.to_s
      party = ((cp.race_id.include? "GOP") ? :GOP : :Dem)
      candidates = race_day.candidate_race_subcounties.select{|cr_sub| cr_sub.geo_id == key}.sort_by(&:n_votes).reverse
      leader = (candidates.first ? {:candidate_id => candidates.first.id, :n_votes => candidates.first.n_votes } : nil)
      obj = (ids[key] ||= { :GOP => {}, :Dem => {}, :n_precincts_total => 0, :n_precincts_reporting => 0})
      obj[:n_precincts_reporting] += cp.n_precincts_reporting
      obj[:n_precincts_total] += cp.n_precincts_total
      obj[party][:n_precincts_reporting] = cp.n_precincts_reporting
      obj[party][:n_precincts_total] = cp.n_precincts_total
      ids[key] = obj
    end
    ids
  end

end
