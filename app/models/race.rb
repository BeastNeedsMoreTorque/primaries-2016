# Could almost be called PartyState. Gives the votes/delegates of a state.
Race = Struct.new(:database, :ap_id, :race_day_id, :party_id, :state_code, :race_type, :n_precincts_reporting, :n_precincts_total, :last_updated, :pollster_slug, :poll_last_updated) do
  include Comparable

  # Sort by date, then state name, then party name
  def <=>(rhs)
    c1 = date.<=>(rhs.date)
    if c1 != 0
      c1
    else
      c2 = state_name.<=>(rhs.state_name)
      if c2 != 0
        c2
      else
        party_name.<=>(rhs.party_name)
      end
    end
  end

  def party; database.parties.find!(party_id); end
  def party_name; party.name; end
  def party_adjective; party.adjective; end
  def race_day; database.race_days.find!(race_day_id); end
  def state; database.states.find!(state_code); end
  def state_fips_int; state.fips_int; end
  def state_name; state.name; end
  def date; race_day.date; end
  def disabled?; !race_day || race_day.disabled?; end
  def enabled?; race_day && race_day.enabled?; end
  def n_delegates; state.n_delegates(party_id); end

  # Determines whether a race is 'future', 'present' or 'past'.
  #
  # These times are relative to the _user_'s clock. In other words, if a race
  # on Feb. 1 has polls that close at 2 a.m. on Feb. 2, then at 1 a.m. on Feb. 2
  # the race will be 'future'; at 2 p.m. the race will be 'present', and when
  # counting is over (later on Feb. 2), the race will be 'past'.
  #
  # JavaScript can live-update this information.
  #
  # Again, here are definitions of the return values:
  #
  # * 'future': voting hasn't finished
  # * 'present': voting has finished; results are not all in
  # * 'past': results are all in
  def when_race_happens
    if !n_precincts_reporting.nil? && n_precincts_reporting > 0
      if n_precincts_reporting < n_precincts_total
        'present'
      else
        'past'
      end
    else
      'future'
    end
  end

  def present?; when_race_happens == 'present'; end
  def past?; when_race_happens == 'past'; end
  def future?; when_race_happens == 'future'; end

  def candidate_states
    @candidate_states ||= database.candidate_states.find_all_by_party_id_and_state_code(party_id, state_code).sort || []
  end

  def candidate_counties
    @candidate_counties ||= database.candidate_counties.find_all_by_party_id_and_state_fips_int(party_id, state_fips_int) || []
  end

  def county_parties
    @county_parties ||= database.county_parties.find_all_by_party_id_and_state_fips_int(party_id, state_fips_int) || []
  end
end
