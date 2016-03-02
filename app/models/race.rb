# Could almost be called PartyState. Gives the votes/delegates of a state.
Race = RubyImmutableStruct.new(
  :database,
  :race_day_id,
  :party_id,
  :state_code,
  :race_type,
  :expect_results_time,
  :text,
  :n_precincts_reporting,
  :n_precincts_total,
  :last_updated,
  :ap_says_its_over,
  :n_votes_th,
  :n_votes_tooltip_th,
  :n_votes_footnote
) do
  include Comparable

  attr_reader(
    :id,
    :candidate_races,
    :candidate_states,
    :candidate_county_races,
    :candidate_race_subcounties,
    :county_races,
    :party_race_day_id,
    :party_state,
    :party_state_id,
    :race_subcounties
  )

  # Something to put after the "#" in a URL
  attr_reader(:anchor)

  def after_initialize
    @id = "#{race_day_id}-#{party_id}-#{state_code}"
    @party_race_day_id = "#{@party_id}-#{@race_day_id}"
    @party_state_id = "#{@party_id}-#{@state_code}"
    @anchor = "#{@state_code}-#{@party_id}"

    @party_state = database.party_states.find!(@party_state_id)
    @candidate_races = database.candidate_races.find_all_by_race_id(@id)
    @candidate_states = @candidate_races.map(&:candidate_state) # via candidate-races to nix dropped-out candidates
    @candidate_states.uniq!
    @candidate_states.compact!
    @candidate_county_races = database.candidate_county_races.find_all_by_race_id(@id) || []
    @candidate_race_subcounties = database.candidate_race_subcounties.find_all_by_race_id(@id) || []
    @county_races = database.county_races.find_all_by_race_id(@id) || []
    @race_subcounties = database.race_subcounties.find_all_by_race_id(@id) || []
  end

  def href
    "/2016/primaries/#{race_day_id}##{anchor}"
  end

  # If this is a GOP-IA race, returns the Dem-IA race.
  #
  # May return nil.
  def other_party_race
    other_party_id = party_id == 'Dem' ? 'GOP' : 'Dem'
    arr = database.races.find_all_by_party_state_id("#{other_party_id}-#{state_code}")
    if arr.length > 1
      throw 'TODO handle case of >1 races per party'
    end
    arr.first
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

  def party; database.parties.find!(party_id); end
  def party_name; party.name; end
  def party_adjective; party.adjective; end
  def race_day; database.race_days.find!(race_day_id); end
  def state; database.states.find!(state_code); end
  def state_fips_int; state.fips_int; end
  def state_name; state.name; end
  def date; race_day.date; end
  def disabled?; race_day.disabled?; end
  def enabled?; race_day.enabled?; end
  def today?; race_day.today?; end
  def n_delegates; party_state.n_delegates; end
  def n_delegates_with_candidates; party_state.n_delegates_with_candidates; end
  def n_pledged_delegates; party_state.n_pledged_delegates; end
  def n_pledged_delegates_with_candidates; party_state.n_pledged_delegates_with_candidates; end
  def pollster_slug; party_state.pollster_slug; end
  def pollster_href; party_state.pollster_href; end
  def pollster_last_updated; party_state.pollster_last_updated; end

  # false iff we have zilch data about how candidates are doing in this race
  def has_any_results_at_all?
    has_pledged_delegate_counts? || any_precincts_reporting? || has_pollster_percents?
  end

  def has_pollster_data?; !pollster_slug.nil?; end
  def has_pollster_percents?; candidate_states.any?{ |cs| !cs.poll_percent.nil? }; end

  # True iff at least one candidate has a delegate -- pledged or unpledged
  def has_delegate_counts?; n_delegates_with_candidates != 0; end
  def has_pledged_delegate_counts?; n_pledged_delegates_with_candidates != 0; end

  # Number of pledged/unpledged delegates not assigned to any candidates
  def n_delegates_without_candidates; n_delegates - n_delegates_with_candidates; end
  def n_pledged_delegates_without_candidates; n_pledged_delegates - n_pledged_delegates_with_candidates; end

  def has_delegates_without_candidates?; n_delegates_without_candidates > 0; end
  def has_pledged_delegates_without_candidates?; n_pledged_delegates_without_candidates > 0; end

  def pct_precincts_reporting
    reporting_str = if n_precincts_total.nil? || n_precincts_total == 0
      'N/A'
    elsif n_precincts_reporting == n_precincts_total
      '100%'
    else
      pct_reporting = (n_precincts_reporting.to_f / n_precincts_total.to_f) * 100.0
      if pct_reporting > 99
        '>99%'
      elsif pct_reporting < 1
        '<1%'
      else
        "#{pct_reporting.round}%"
      end
    end
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
    elsif state_code == 'NH' && !expect_results_time.nil? && database.now < expect_results_time
      # In NH, some results come in at midnight the night before. They're
      # confusing because they make it look like the polls are closed before
      # they're even open.
      'future'
    elsif any_precincts_reporting?
      if n_precincts_reporting < n_precincts_total
        'present'
      else
        'past'
      end
    elsif !expect_results_time.nil? && database.now >= expect_results_time
      # If AP says results are coming, say it's present. That way we'll see the
      # little refresh countdowns.
      'present'
    else
      'future'
    end
  end

  def present?; when_race_happens == 'present'; end
  def past?; when_race_happens == 'past'; end
  def future?; when_race_happens == 'future'; end

  def any_precincts_reporting?; (n_precincts_reporting || 0) > 0; end
  def all_precincts_reporting?; !n_precincts_reporting.nil? && n_precincts_reporting == n_precincts_total; end

  # Returns something like:
  #
  # * "Results coming February 20" (if not today)
  # * "Results coming 7:00 p.m. EST" (if expect_results_time)
  # * "Results coming soon" (if expect_results_time.nil?)
  def results_coming_s
    if database.today < race_day_id
      "Results coming #{date.strftime('%B %-d')}"
    elsif expect_results_time.nil?
      "Results coming soon"
    else
      "Results coming #{expect_results_time.to_datetime.new_offset('Eastern').strftime('%l:%M %P %Z').sub('m', '.m.').sub('-05:00', 'EST').sub('-04:00', 'EDT')}"
    end
  end

  # e.g., 'Iowa Democratic Caucus'
  def title
    throw "#{race_day_id} #{party_id} #{state_code} race needs a race_type. Update the spreadsheet and run script/update-static-data" if !race_type
    "#{state_name} #{party_adjective} #{race_type}"
  end

  # e.g., "Iowa (D)'
  def title_abbr
    "#{state_name} (#{party.abbreviation})"
  end
end
