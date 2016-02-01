require 'date'
require 'set'

require_relative '../../lib/api_sources'
require_relative '../../lib/sparkline'
require_relative '../collections/parties'
require_relative '../collections/race_days'
require_relative '../sources/ap_del_super_source'
require_relative '../sources/ap_election_days_source'

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

    del_super = ApDelSuperSource.new(ApiSources.GET_del_super)
    for candidate in del_super.candidates
      full_name = id_to_candidate_full_name[candidate.id]
      candidates << candidate.merge(name: full_name)
      id_to_candidate[candidate.id] = candidate
    end
    for candidate_state in del_super.candidate_states
      candidate_states << candidate_state
      ids_to_candidate_state[[candidate_state.candidate_id, candidate_state.state_code]] = candidate_state
    end
    for party in del_super.parties
      party_extra = Parties.extra_attributes_by_id.fetch(party.id.to_sym)
      parties << party.merge(party_extra)
    end

    ap_election_days = ApElectionDaysSource.new(ApiSources.GET_all_primary_election_days)

    id_to_candidate_state = {}
    for candidate_state in ap_election_days.candidate_states
      id_to_candidate_state[candidate_state.id] = candidate_state
    end
    candidate_states.map! { |cs| cs2 = id_to_candidate_state[cs.id]; cs2 ? cs.merge(ballot_order: cs2.ballot_order, n_votes: cs2.n_votes) : cs }

    candidate_counties = ap_election_days.candidate_counties

    counties = ap_election_days.counties

    county_parties = ap_election_days.county_parties

    races = ap_election_days.races

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

    candidates.select! { |c| candidate_ids.include?(c.id) }
    candidate_states.select! { |cs| candidate_ids.include?(cs.candidate_id) }
    candidate_counties.select! { |cc| candidate_ids.include?(cc.candidate_id) }
  end

  # Adds :dropped_out_date to candidates from the copy. Nixes candidate_states
  # and candidate_counties that we should never show.
  def self.drop_out_candidates_from_copy(copy, candidates, races, candidate_states)
    full_name_to_candidate = {}
    candidate_id_to_party_id = {}
    for candidate in candidates
      candidate_id_to_party_id[candidate.id] = candidate.party_id
      full_name_to_candidate[candidate.name] = candidate
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

      candidate_id_to_last_race_day_id[candidate[0]] = date
    end

    candidates.map! do |c|
      date = candidate_id_to_last_race_day_id[c.id]
      date ? c.merge(dropped_out_date: Date.parse(date)) : c
    end

    party_id_state_code_to_first_race_day_id = {}
    for race in races
      key = "#{race.party_id}-#{race.state_code}"
      race_day_id = race.race_day_id
      if !party_id_state_code_to_first_race_day_id[key] || party_id_state_code_to_first_race_day_id[key] > race_day_id
        party_id_state_code_to_first_race_day_id[key] = race_day_id
      end
    end

    candidate_states.select! do |candidate_state|
      candidate_id = candidate_state.candidate_id
      drop_out_date = candidate_id_to_last_race_day_id[candidate_id]

      if !drop_out_date
        true
      else
        state_code = candidate_state.state_code
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
    existing_race_keys = races.map(&:id).to_set # race_day_id-party_id-state_code

    RaceDays::HardCodedData.each do |date_sym, party_races|
      race_day_id = date_sym.to_s
      party_races.each do |party_id_sym, state_code_syms|
        party_id = party_id_sym.to_s
        state_code_syms.each do |state_code_sym|
          state_code = state_code_sym.to_s
          race_id = "#{race_day_id}-#{party_id}-#{state_code}"
          next if existing_race_keys.include?(race_id)

          races << Race.new(nil, nil, race_day_id, party_id, state_code)
        end
      end
    end
  end

  def self.mark_races_finished_from_copy(copy, races)
    called_race_keys = Set.new
    for copy_race in copy['primaries']['races']
      if copy_race['over'] == 'true'
        called_race_keys.add("#{copy_race['party']}-#{copy_race['state']}")
      end
    end

    races.map! do |race|
      race_key = "#{race.party_id}-#{race.state_code}"
      called_race_keys.include?(race_key) ? race.merge(ap_says_its_over: true) : race
    end

    nil
  end

  # Writes Candidate.poll_percent, Candidate.poll_updated_at,
  # CandidateState.poll_percent, Race.poll_last_updated.
  def self.add_pollster_estimates(parties, candidates, candidate_states, races)
    key_to_races = {}
    races.each do |race|
      key = "#{race.party_id}-#{race.state_code}"
      key_to_races[key] ||= []
      key_to_races[key] << race
    end

    last_name_to_candidate_id = {} # but also full_name, because Pollster has a :choice => "Rand Paul"

    candidates.each { |c| last_name_to_candidate_id[c.last_name] = last_name_to_candidate_id[c.name] = c.id }

    chart_slugs = []

    race_key_to_pollster = {} # party_id-state_code -> [ slug, last_updated ]
    candidate_state_id_to_pollster = {} # candidate_id-state_code -> [ poll_percent, sparkline ]
    candidate_id_to_pollster = {} # candidate_id -> [ poll_percent, sparkline, last_updated ]

    for party in parties
      party_id = party.id

      for chart in ApiSources.GET_pollster_primaries(party_id)
        state_code = chart[:state]
        last_updated = DateTime.parse(chart[:last_updated])
        slug = chart[:slug]

        race_key = "#{party_id}-#{state_code}"
        race_key_to_pollster[race_key] = [ slug, last_updated ]

        chart_slugs << slug

        for estimate in chart[:estimates]
          last_name = estimate[:last_name]

          candidate_id = last_name_to_candidate_id[last_name]
          if candidate_id
            poll_percent = estimate[:value]

            if state_code == 'US'
              candidate_id_to_pollster[candidate_id] = [ poll_percent, nil, last_updated ]
            else
              candidate_state_id_to_pollster["#{candidate_id}-#{state_code}"] = [ poll_percent, nil ]
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

            candidate_id = last_name_to_candidate_id[choice]
            next if !candidate_id

            if state_code == 'US'
              pollster_candidate = candidate_id_to_pollster[candidate_id]
              next if !pollster_candidate
              pollster_candidate[1] ||= Sparkline.new(last_day)
              pollster_candidate[1].add_value(date, value)
            else
              key = "#{candidate_id}-#{state_code}"
              candidate_state = candidate_state_id[key]
              next if !candidate_state
              candidate_state[1] ||= Sparkline.new(last_day)
              candidate_state[1].add_value(date, value)
            end
          end
        end
      end
    end

    races.map! do |race|
      pollster = race_key_to_pollster["#{race.party_id}-#{race.state_code}"]
      pollster ? race.merge(pollster_slug: pollster[0], poll_last_updated: pollster[1]) : race
    end

    candidates.map! do |candidate|
      pollster = candidate_id_to_pollster[candidate.id]
      pollster ? candidate.merge(poll_percent: pollster[0], poll_sparkline: pollster[1], poll_last_update: pollster[2]) : candidate
    end

    candidate_states.map! do |candidate_state|
      pollster = candidate_state_key_to_pollster[candidate_state.id]
      pollster ? candidate_state.merge(poll_percent: pollster[0], poll_sparkline: pollster[1]) : candidate_state
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
