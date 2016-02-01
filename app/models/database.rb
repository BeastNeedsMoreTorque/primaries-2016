require 'date'
require 'set'

require_relative '../../lib/api_sources'
require_relative '../../lib/sparkline'
require_relative '../collections/parties'
require_relative '../collections/race_days'

# All data that goes into page rendering.
#
# Once you build a Database, nothing will change.
#
# The Database contains every Collection we use -- e.g., `candidates`, `states`
# -- plus the rendering date.
class Database
  LastDate = Date.parse(ENV['LAST_DATE'] || '2016-02-09') # because we haven't coded+tested everything yet

  # Order these collections correctly: when each is built it will be sorted,
  # and if it depends on other collections that aren't initialized yet, the
  # sort will crash.
  CollectionNames = %w(
    counties
    parties
    candidates
    states
    candidate_counties
    candidate_states
    county_parties
    races
    race_days
  )

  attr_reader(*CollectionNames)
  attr_reader(:today)
  attr_reader(:last_date)
  attr_reader(:copy)

  def initialize(collections, today, last_date, copy)
    CollectionNames.each { |n| require_relative "../collections/#{n}.rb" }

    CollectionNames.each do |collection_name|
      collection_class_name = collection_name.gsub(/(?:^|_)(\w)/) { $1.upcase }
      collection_class = Object.const_get(collection_class_name)

      all = collections[collection_name.to_sym]

      collection = if all
        collection_class.build(self, all)
      elsif collection_class.respond_to?(:build_hard_coded)
        collection_class.build_hard_coded(self)
      else
        # Integration tests use this
        collection_class.build(self, [])
      end

      instance_variable_set("@#{collection_name}", collection)
    end

    @today = today
    @last_date = last_date
    @copy = copy
  end

  def inspect
    "#<Database>"
  end

  # The "production" Database: today's date, AP's data
  #
  # If AP_TEST=true, we use AP's test data.
  def self.load(options={})
    override_copy = options[:override_copy] || {}
    copy = production_copy(override_copy)

    candidates = []
    candidate_counties = []
    candidate_states = []
    counties = []
    county_parties = []
    parties = []
    races = []

    id_to_candidate = {}
    seen_county_ids = Set.new([])
    ids_to_candidate_state = {}

    id_to_candidate_full_name = {}
    for copy_candidate in copy['candidates']
      id_to_candidate_full_name[copy_candidate['id']] = copy_candidate['name']
    end

    # Fill CandidateState (no ballot_order or n_votes) and Candidate (no name)
    for del in ApiSources.GET_del_super[:del]
      party_id = del[:pId]
      party_extra = Parties.extra_attributes_by_id.fetch(party_id.to_sym)

      parties << [ party_id, party_extra[:name], party_extra[:adjective], del[:dVotes], del[:dNeed] ]

      for del_state in del[:State]
        state_code = del_state[:sId]
        next if state_code == 'UN' # "Unassigned super delegates"
        for del_candidate in del_state[:Cand]
          candidate_id = del_candidate[:cId]
          last_name = del_candidate[:cName]
          next if candidate_id.length >= 6
          n_delegates = del_candidate[:dTot].to_i
          n_unpledged_delegates = del_candidate[:sdTot].to_i

          if state_code == 'US'
            full_name = id_to_candidate_full_name[candidate_id]
            c = [ candidate_id, party_id, full_name, last_name, n_delegates, n_unpledged_delegates, nil, nil, nil ]
            candidates << c
            id_to_candidate[candidate_id] = c
          else
            cs = [ candidate_id, state_code, -1, 0, n_delegates, nil, nil ]
            candidate_states << cs
            ids_to_candidate_state[[candidate_id, state_code]] = cs
          end
        end
      end
    end

    for election_day in ApiSources.GET_all_primary_election_days
      race_day_id = election_day[:electionDate]
      for race_hash in election_day[:races]
        race_id = race_hash[:raceID]
        party_id = race_hash[:party]
        race_type = race_hash[:raceType]

        # If the race is in the future, AP will put a :statePostal here.
        # If the race is today or in the past, AP will omit this :statePostal
        # and add one to the state :reportingUnit instead
        state_code = race_hash[:statePostal]

        # If the race is in the future, AP will have no :reportingUnits, and it
        # will put the :lastUpdated in the main hash. If the race is today, AP
        # will omit this :lastUpdated; we'll use the :lastUpdated on the state
        # :reportingUnit instead.
        last_updated = race_hash[:lastUpdated] ? DateTime.parse(race_hash[:lastUpdated]) : nil

        race = [ race_id, race_day_id, party_id, state_code, race_type, nil, nil, last_updated, nil, nil, nil ]
        races << race

        for reporting_unit in (race_hash[:reportingUnits] || [])
          n_precincts_reporting = reporting_unit[:precinctsReporting]
          n_precincts_total = reporting_unit[:precinctsTotal]

          if reporting_unit[:level] == 'state'
            # As described above: if this reporting_unit is set, that means AP
            # didn't give us a state_code or last_updated above, so we need to
            # set them now.
            state_code = reporting_unit[:statePostal]
            last_updated = DateTime.parse(reporting_unit[:lastUpdated])

            race[3] = state_code
            race[7] = last_updated

            race[5] = n_precincts_reporting
            race[6] = n_precincts_total

            for candidate_hash in reporting_unit[:candidates]
              candidate_id = candidate_hash[:polID]
              next if candidate_id.length >= 6
              candidate = id_to_candidate[candidate_id]

              next if !candidate

              candidate_state = ids_to_candidate_state[[candidate_id, state_code]]

              if !candidate_state
                raise "Missing candidate-state pair #{candidate_id}-#{state_code}"
              end

              candidate_state[2] = candidate_hash[:ballotOrder]
              candidate_state[3] = candidate_hash[:voteCount]
            end
          elsif reporting_unit[:level] == 'FIPSCode'
            fips_code = reporting_unit[:fipsCode]
            county_id = fips_code.to_i # Don't worry, Ruby won't parse '01234' as octal

            if !seen_county_ids.include?(county_id)
              counties << [ county_id ]
              seen_county_ids.add(county_id)
            end

            county_parties << [ county_id, party_id, n_precincts_reporting, n_precincts_total, last_updated ]

            for candidate_hash in reporting_unit[:candidates]
              candidate_id = candidate_hash[:polID]
              candidate = id_to_candidate[candidate_id]

              next if !candidate

              n_votes = candidate_hash[:voteCount]

              candidate_counties << [ party_id, candidate_id, county_id, n_votes ]
            end
          else
            raise "Invalid reporting unit level `#{reporting_unit[:level]}'"
          end
        end
      end
    end

    fix_invalid_ap_candidate_data(copy, candidates, candidate_states, candidate_counties)
    drop_out_candidates_from_copy(copy, candidates, races, candidate_states)
    mark_races_finished_from_copy(copy, races)
    stub_races_ap_isnt_reporting_yet(races)
    add_pollster_estimates(parties, candidates, candidate_states, races)

    Database.new({
      candidates: candidates,
      candidate_counties: candidate_counties,
      candidate_states: candidate_states,
      counties: counties,
      county_parties: county_parties,
      parties: parties,
      races: races
    }, Date.today, LastDate, copy)
  end

  # Removes candidates AP shouldn't be reporting to us, and override AP's
  # delegate counts.
  #
  # Prior to 2016-01-31, AP reports the wrong list of candidates and the
  # wrong delegate counts. We put the correct data in our `copy`.
  def self.fix_invalid_ap_candidate_data(copy, candidates, candidate_states, candidate_counties)
    candidate_ids = Set.new(copy.fetch('candidates', []).map{ |c| c['id'] })

    candidates.select! { |arr| candidate_ids.include?(arr[0]) }
    candidate_states.select! { |arr| candidate_ids.include?(arr[0]) }
    candidate_counties.select! { |arr| candidate_ids.include?(arr[1]) }
  end

  # Adds :dropped_out_date to candidates from the copy. Nixes candidate_states
  # and candidate_counties that we should never show.
  def self.drop_out_candidates_from_copy(copy, candidates, races, candidate_states)
    full_name_to_candidate = {}
    candidate_id_to_party_id = {}
    for candidate in candidates
      candidate_id_to_party_id[candidate[0]] = candidate[1]
      full_name_to_candidate[candidate[2]] = candidate
    end

    candidate_id_to_last_race_day_id = {} # id -> "YYYY-MM-DD"

    for candidate_copy in copy['candidates']
      next if !candidate_copy['dropped out']

      date = Date.parse(candidate_copy['dropped out'])
      if date > Date.parse('2016-07-01') || date < Date.parse('2016-01-01')
        throw "The drop-out date of #{date} for #{candidate_copy['name']} is clearly a mistake in the copy. Aborting."
      end

      candidate = full_name_to_candidate[candidate_copy['name']]
      if !candidate
        throw "The candidate named #{candidate_copy['name']} does not exist and is thus a mistake in the copy. Aborting."
      end

      candidate[9] = date
      candidate_id_to_last_race_day_id[candidate[0]] = date.to_s
    end

    party_id_state_code_to_first_race_day_id = {}
    for race in races
      key = "#{race[2]}-#{race[3]}"
      race_day_id = race[1]
      if !party_id_state_code_to_first_race_day_id[key] || party_id_state_code_to_first_race_day_id[key] > race_day_id
        party_id_state_code_to_first_race_day_id[key] = race_day_id
      end
    end

    candidate_states.select! do |candidate_state|
      candidate_id = candidate_state[0]
      drop_out_date = candidate_id_to_last_race_day_id[candidate_id]

      if !drop_out_date
        true
      else
        state_code = candidate_state[1]
        party_id = candidate_id_to_party_id[candidate_id]
        key = "#{party_id}-#{state_code}"
        race_day_id = party_id_state_code_to_first_race_day_id[key]
        !race_day_id || race_day_id <= drop_out_date
      end
    end
  end

  # Adds more races to the passed Array of races.
  #
  # They'll have lots of nils.
  def self.stub_races_ap_isnt_reporting_yet(races)
    # Create unique key
    existing_race_keys = Set.new() # "key" means race_day.id, party.id, state.code
    races.each { |r| existing_race_keys.add(r[1...4].join(',')) }

    RaceDays::HardCodedData.each do |date_sym, party_races|
      race_day_id = date_sym.to_s
      party_races.each do |party_id_sym, state_code_syms|
        party_id = party_id_sym.to_s
        state_code_syms.each do |state_code_sym|
          state_code = state_code_sym.to_s
          key = "#{race_day_id},#{party_id},#{state_code}"
          next if existing_race_keys.include?(key)

          races << [ nil, race_day_id, party_id, state_code, nil, nil, nil, nil, nil ]
        end
      end
    end
  end

  def self.mark_races_finished_from_copy(copy, races)
    called_race_keys = Set.new
    for copy_race in copy['primaries']['races']
      if copy_race['over'] == 'true'
        called_race_keys << "#{copy_race['party']}-#{copy_race['state']}"
      end
    end

    for race in races
      race_key = "#{race[2]}-#{race[3]}"
      if called_race_keys.include?(race_key)
        race[10] = true
      end
    end

    nil
  end

  # Writes Candidate.poll_percent, Candidate.poll_updated_at,
  # CandidateState.poll_percent, Race.poll_last_updated.
  def self.add_pollster_estimates(parties, candidates, candidate_states, races)
    # Pollster reports "choice: 'Rand Paul'" and "choice: 'Santorum'", so we
    # need to index by both last name and full name.
    last_name_to_candidate = {}
    full_name_to_candidate = {}
    candidates.each { |c| last_name_to_candidate[c[3]] = c }
    candidates.each { |c| full_name_to_candidate[c[2]] = c }

    key_to_candidate_state = {}
    candidate_states.each { |cs| key_to_candidate_state["#{cs[0]}-#{cs[1]}"] = cs }

    key_to_races = {}
    races.each do |race|
      key = "#{race[2]}-#{race[3]}"
      key_to_races[key] ||= []
      key_to_races[key] << race
    end

    chart_slugs = []

    for party in parties
      party_id = party[0]

      for chart in ApiSources.GET_pollster_primaries(party_id)
        state_code = chart[:state]
        last_updated = DateTime.parse(chart[:last_updated])
        slug = chart[:slug]
        chart_slugs << slug

        for race in (key_to_races["#{party_id}-#{state_code}"] || [])
          race[8] = slug
          race[9] = last_updated
        end

        for estimate in chart[:estimates]
          last_name = estimate[:last_name]

          candidate = last_name_to_candidate[last_name]
          if candidate
            poll_percent = estimate[:value]

            if state_code == 'US'
              candidate[6] = poll_percent
              candidate[8] = last_updated
            else
              candidate_state = key_to_candidate_state["#{candidate[0]}-#{state_code}"]
              if candidate_state
                candidate_state[5] = poll_percent
              end
            end
          end
        end
      end

      for slug in chart_slugs
        chart_data = ApiSources.GET_pollster_primary(slug)
        state_code = chart_data[:state]

        last_day = if chart_data[:election_date]
          [ Date.today, Date.parse(chart_data[:election_date]) ].min
        else
          Date.today
        end

        for estimate_points in chart_data[:estimates_by_date]
          date = Date.parse(estimate_points[:date])

          for estimate in estimate_points[:estimates]
            choice = estimate[:choice]
            value = estimate[:value]

            candidate = last_name_to_candidate[choice] || full_name_to_candidate[choice]
            next if !candidate

            if state_code == 'US'
              candidate[7] ||= Sparkline.new(last_day)
              candidate[7].add_value(date, value)
            else
              key = "#{candidate[0]}-#{state_code}"
              candidate_state = key_to_candidate_state[key]
              if candidate_state # *Our* candidate may have dropped out before Pollster noticed
                candidate_state[6] ||= Sparkline.new(last_day)
                candidate_state[6].add_value(date, value)
              end
            end
          end
        end
      end
    end

    nil
  end

  def self.production_copy(override_copy={})
    @production_copy ||= begin
      text = IO.read(Paths.Copy)
      Archieml.load(text)
    end

    self.override_copy(@production_copy, override_copy)
  end

  private

  def self.override_copy(copy, overrides)
    copy = Marshal.load(Marshal.dump(copy)) # deep clone
    overrides.each do |key_with_dots, value|
      keys = key_with_dots.to_s.split('.')
      last_key = keys.pop
      copy_subhash = copy
      for key in keys
        if key.include?('=')
          clauses = key.split(/,/)
          for clause in clauses
            k, v = clause.split(/=/)
            copy_subhash = copy_subhash.select { |o| o[k] == v }
          end
          copy_subhash = copy_subhash.first
        else
          copy_subhash = copy_subhash[key]
        end
        throw "Invalid key in overrides: `#{key_with_dots}`. An example of a valid key is `landing-page.hed` or `candidates.name=Hillary Clinton.dropped out`." if !copy_subhash
      end
      copy_subhash[last_key] = value
    end
    copy
  end
end
