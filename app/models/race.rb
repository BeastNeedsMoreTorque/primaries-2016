# Could almost be called PartyState. Gives the votes/delegates of a state.
Race = RubyImmutableStruct.new(
  :database_or_nil,
  :race_day_id,
  :party_id,
  :state_code,
  :race_type,
  :text,
  :n_precincts_reporting,
  :n_precincts_total,
  :last_updated,
  :ap_says_its_over
) do
  include Comparable

  # Sum of candidate_states.n_delegates (pledged and unpledged alike)
  attr_reader(:n_delegates_with_candidates)

  attr_reader(:id, :candidate_races, :candidate_states, :candidate_counties, :county_parties, :party_state)

  attr_reader(:party_state_id)

  def after_initialize
    @id = "#{race_day_id}-#{party_id}-#{state_code}"
    @party_state_id = "#{@party_id}-#{@state_code}"

    if !database_or_nil.nil?
      database = database_or_nil

      @party_state = database.party_states.find!(@party_state_id)
      @candidate_races = database.candidate_races.find_all_by_race_id(@id)
      @candidate_states = @candidate_races.map(&:candidate_state) # via candidate-races to nix dropped-out candidates
      @candidate_states.uniq!
      @candidate_states.compact!
      @candidate_counties = database.candidate_counties.find_all_by_party_id_and_state_fips_int(party_id, state_fips_int) || []
      @county_parties = database.county_parties.find_all_by_party_id_and_state_fips_int(party_id, state_fips_int) || []

      @n_delegates_with_candidates = @candidate_states.map(&:n_delegates).reduce(0, :+)
    end
  end

  def n_votes_is_really_n_sdes
    party_id == 'Dem' && state_code == 'IA'
  end

  # Sort by date, then state name, then party name
  def <=>(rhs)
    c1 = race_day_id.<=>(rhs.race_day_id)
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

  def party; database_or_nil.parties.find!(party_id); end
  def party_name; party.name; end
  def party_adjective; party.adjective; end
  def race_day; database_or_nil.race_days.find!(race_day_id); end
  def state; database_or_nil.states.find!(state_code); end
  def state_fips_int; state.fips_int; end
  def state_name; state.name; end
  def date; race_day.date; end
  def disabled?; race_day.disabled?; end
  def enabled?; race_day.enabled?; end
  def n_delegates; party_state.n_delegates; end
  def pollster_slug; party_state.pollster_slug; end
  def pollster_last_updated; party_state.pollster_last_updated; end

  # True iff at least one candidate has a delegate -- pledged or unpledged
  def has_delegate_counts
    n_delegates_with_candidates != 0
  end

  # Number of pledged/unpledged delegates not assigned to any candidates
  def n_delegates_without_candidates
    n_delegates - n_delegates_with_candidates
  end

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
    if ap_says_its_over
      'past'
    elsif !n_precincts_reporting.nil? && n_precincts_reporting > 0
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

  # e.g., 'Iowa Democratic Caucus'
  def title
    "#{state_name} #{party_adjective} #{race_type}"
  end
end
