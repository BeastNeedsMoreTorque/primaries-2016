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
    parties
    candidates
    states
    candidate_counties
    candidate_states
    counties
    county_parties
    race_days
    races
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

  # The "production" Database: today's date, AP's data
  #
  # If AP_TEST=true, we use AP's test data.
  def self.load
    copy = production_copy

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
            c = [ candidate_id, party_id, nil, last_name, n_delegates, n_unpledged_delegates, nil, nil ]
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

        race = [ race_id, race_day_id, party_id, nil, race_type, nil, nil, nil, nil ]
        races << race

        for reporting_unit in race_hash[:reportingUnits]
          n_precincts_reporting = reporting_unit[:precinctsReporting]
          n_precincts_total = reporting_unit[:precinctsTotal]

          if reporting_unit[:level] == 'state'
            last_updated = DateTime.parse(reporting_unit[:lastUpdated])
            state_code = reporting_unit[:statePostal]

            race[3] = state_code
            race[5] = n_precincts_reporting
            race[6] = n_precincts_total
            race[7] = last_updated

            for candidate_hash in reporting_unit[:candidates]
              candidate_id = candidate_hash[:polID]
              next if candidate_id.length >= 6
              candidate = id_to_candidate[candidate_id]

              next if !candidate

              candidate_state = ids_to_candidate_state[[candidate_id, state_code]]

              if !candidate[2] # name
                first_name = candidate_hash[:first]
                last_name = candidate_hash[:last]
                candidate[2] ||= "#{first_name} #{last_name}".strip
              end

              if !candidate_state
                raise "Missing candidate-state pair #{candidate.id}-#{state_code}"
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

            county_parties << [ county_id, party_id, n_precincts_reporting, n_precincts_reporting, last_updated ]

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

  # Writes Candidate.poll_percent, Candidate.poll_updated_at,
  # CandidateState.poll_percent, Race.poll_last_updated.
  def self.add_pollster_estimates(parties, candidates, candidate_states, races)
    last_name_to_candidate = {}
    candidates.each { |c| last_name_to_candidate[c[3]] = c }

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
            last_name = estimate[:choice]
            value = estimate[:value]

            candidate = last_name_to_candidate[last_name]
            next if !candidate

            if state_code == 'US'
              candidate[7] ||= Sparkline.new(last_day)
              candidate[7].add_value(date, value)
            else
              key = "#{candidate[0]}-#{state_code}"
              candidate_state = key_to_candidate_state[key]
              candidate_state[6] ||= Sparkline.new(last_day)
              candidate_state[6].add_value(date, value)
            end
          end
        end
      end
    end

    nil
  end

  def self.production_copy
    @production_copy ||= begin
      text = IO.read(Paths.Copy)
      Archieml.load(text)
    end
  end
end
