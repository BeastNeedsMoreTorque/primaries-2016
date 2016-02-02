require 'date'
require 'set'

require_relative '../../lib/api_sources'
require_relative '../collections/race_days'
require_relative '../models/candidate'
require_relative '../models/candidate_county'
require_relative '../models/candidate_state'
require_relative '../models/county'
require_relative '../models/county_party'
require_relative '../models/party'
require_relative '../models/race'
require_relative '../models/race_day'
require_relative '../sources/ap_del_super_source'
require_relative '../sources/ap_election_days_source'
require_relative '../sources/copy_source'
require_relative '../sources/pollster_source'

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

    copy_source = CopySource.new(IO.read(Paths.Copy))
    ap_del_super = ApDelSuperSource.new(ApiSources.GET_del_super)
    ap_election_days = ApElectionDaysSource.new(ApiSources.GET_all_primary_election_days)
    pollster_source = load_pollster_source(copy_source.parties, ap_election_days.races, LastDate)

    candidates = load_candidates(copy_source.candidates, ap_del_super.candidates, pollster_source.candidates)
    candidate_counties = load_candidate_counties(copy_source.candidates, ap_election_days.candidate_counties)
    candidate_states = load_candidate_states(copy_source.candidates, ap_election_days.candidate_states, ap_del_super.candidates, ap_del_super.candidate_states, pollster_source.candidate_states)
    counties = load_counties(ap_election_days.county_fips_ints)
    county_parties = load_county_parties(ap_election_days.county_parties)
    parties = load_parties(copy_source.parties, ap_del_super.parties)
    races = load_races(copy_source.races, ap_election_days.races, pollster_source.candidate_states, ap_del_super.candidates)

    drop_out_candidates(copy_source.candidates, races, candidate_states) # TODO refactor so this isn't here
    stub_races_ap_isnt_reporting_yet(races) # TODO refactor so this isn't here

    Database.new({
      candidates: candidates,
      candidate_counties: candidate_counties,
      candidate_states: candidate_states,
      counties: counties,
      county_parties: county_parties,
      parties: parties,
      races: races
    }, Date.today, LastDate, copy_source.raw_data)
  end

  def self.load_candidates(copy_candidates, ap_del_super_candidates, pollster_candidates)
    last_name_to_candidate_id = {}
    candidate_id_to_del_super_candidate = {}
    for del_super_candidate in ap_del_super_candidates
      last_name_to_candidate_id[del_super_candidate.last_name] = del_super_candidate.id
      candidate_id_to_del_super_candidate[del_super_candidate.id] = del_super_candidate
    end

    candidate_id_to_pollster_candidate = {}
    for pollster_candidate in pollster_candidates
      candidate_id = last_name_to_candidate_id[pollster_candidate.last_name]
      if candidate_id
        candidate_id_to_pollster_candidate[candidate_id] = pollster_candidate
      end
    end

    copy_candidates.map do |copy_candidate|
      del_super_candidate = candidate_id_to_del_super_candidate[copy_candidate.id]
      pollster_candidate = candidate_id_to_pollster_candidate[copy_candidate.id]

      Candidate.new(
        nil,
        copy_candidate.id,
        copy_candidate.party_id,
        copy_candidate.full_name,
        del_super_candidate.last_name,
        del_super_candidate.n_delegates,
        del_super_candidate.n_unpledged_delegates,
        pollster_candidate ? pollster_candidate.poll_percent : nil,
        pollster_candidate ? pollster_candidate.sparkline : nil,
        pollster_candidate ? pollster_candidate.last_updated : nil,
        copy_candidate.dropped_out_date_or_nil
      )
    end
  end

  def self.load_candidate_counties(copy_candidates, ap_candidate_counties)
    valid_candidate_ids = Set.new(copy_candidates.map(&:id))

    ap_candidate_counties
      .select { |candidate_county| valid_candidate_ids.include?(candidate_county.candidate_id) }
      .map! { |cc| CandidateCounty.new(nil, cc.party_id, cc.candidate_id, cc.fips_int, cc.n_votes) }
  end

  def self.load_candidate_states(copy_candidates, ap_candidate_states, del_super_candidates, del_super_candidate_states, pollster_candidate_states)
    valid_candidate_ids = Set.new(copy_candidates.map(&:id))

    last_name_to_party_id = del_super_candidates.each_with_object({}) { |c, h| h[c.last_name] = c.party_id }

    id_to_ap_candidate_state = ap_candidate_states.each_with_object({}) { |cs, h| h[cs.id] = cs }

    id_to_pollster_candidate_state = pollster_candidate_states.each_with_object({}) do |pollster_candidate_state, h|
      party_id = last_name_to_party_id[pollster_candidate_state.last_name]
      if party_id
        id = "#{party_id}-#{pollster_candidate_state.state_code}"
        h[id] = pollster_candidate_state
      end
    end

    # TODO drop out candidates here, treating the list of races as a Source
    del_super_candidate_states
      .select { |candidate_state| valid_candidate_ids.include?(candidate_state.candidate_id) }
      .map! do |del_super_candidate_state|
        ap_candidate_state = id_to_ap_candidate_state[del_super_candidate_state.id]
        pollster_candidate_state = id_to_pollster_candidate_state[del_super_candidate_state.id]

        CandidateState.new(
          nil,
          del_super_candidate_state.candidate_id,
          del_super_candidate_state.state_code,
          ap_candidate_state ? ap_candidate_state.ballot_order : nil,
          ap_candidate_state ? ap_candidate_state.n_votes : nil,
          del_super_candidate_state.n_delegates,
          pollster_candidate_state ? pollster_candidate_state.poll_percent : nil,
          pollster_candidate_state ? pollster_candidate_state.sparkline : nil,
          ap_candidate_state ? ap_candidate_state.winner : false
        )
      end
  end

  def self.load_counties(ap_county_fips_ints)
    ap_county_fips_ints.to_a
      .map! { |fips_int| County.new(nil, fips_int) }
  end

  def self.load_county_parties(ap_county_parties)
    ap_county_parties
      .map! do |ap_county_party|
        CountyParty.new(
          nil,
          ap_county_party.fips_int,
          ap_county_party.party_id,
          ap_county_party.n_precincts_reporting,
          ap_county_party.n_precincts_total,
          ap_county_party.last_updated
        )
      end
  end

  def self.load_parties(copy_parties, del_super_parties)
    id_to_del_super_party = del_super_parties.each_with_object({}) { |p, h| h[p.id] = p }

    copy_parties.map do |copy_party|
      del_super_party = id_to_del_super_party[copy_party.id]
      Party.new(
        nil,
        copy_party.id,
        copy_party.name,
        copy_party.adjective,
        del_super_party.n_delegates_total,
        del_super_party.n_delegates_needed
      )
    end
  end

  def self.load_races(copy_races, ap_races, pollster_candidate_states, del_super_candidates)
    last_name_to_candidate_id = del_super_candidates.each_with_object({}) { |c, h| h[c.last_name] = c.id }

    key_to_pollster_info = pollster_candidate_states.each_with_object({}) do |cs, h|
      candidate_id = last_name_to_candidate_id[cs.last_name]
      if candidate_id
        key = "#{candidate_id}-#{cs.state_code}"
        if !h.include?(key)
          h[key] = cs
        end
      end
    end

    id_to_copy_race = copy_races.each_with_object({}) { |r, h| h[r.id] = r }

    # TODO fill in all races, by putting then in a spreadsheet and using it as a Source
    ap_races.map do |ap_race|
      key = "#{ap_race.party_id}-#{ap_race.state_code}"
      copy_race = id_to_copy_race[ap_race.id]
      pollster_info = key_to_pollster_info[key]

      Race.new(
        nil,
        ap_race.race_day_id,
        ap_race.party_id,
        ap_race.state_code,
        ap_race.race_type,
        ap_race.n_precincts_reporting,
        ap_race.n_precincts_total,
        ap_race.last_updated,
        pollster_info ? pollster_info.slug : nil,
        pollster_info ? pollster_info.last_updated : nil,
        copy_race ? copy_race.over : false
      )
    end
  end

  # Nixes candidate_states and candidate_counties that we should never show.
  def self.drop_out_candidates(candidates, races, candidate_states)
    candidate_id_to_party_id = candidates.each_with_object({}) { |c, h| h[c.id] = c.party_id }
    candidate_id_to_dropped_out_date_s = candidates.each_with_object({}) do |c, h|
      date_or_nil = c.dropped_out_date_or_nil
      if date_or_nil
        h[c.id] = date_or_nil.to_s
      end
    end

    race_key_to_first_race_day_id = races.each_with_object({}) do |race, h|
      # Assume races are ordered from earliest to latest
      h[race.party_id_and_state_code] ||= race.race_day_id
    end

    candidate_states.select! do |candidate_state|
      candidate_id = candidate_state.candidate_id
      party_id = candidate_id_to_party_id[candidate_id]
      race_key = "#{party_id}-#{candidate_state.state_code}"
      first_race_day_id = race_key_to_first_race_day_id[race_key]
      dropped_out_date_s = candidate_id_to_dropped_out_date_s[candidate_id]

      first_race_day_id && (!dropped_out_date_s || dropped_out_date_s >= first_race_day_id)
    end
  end

  # Adds more races to the passed Array of races.
  #
  # They'll have lots of nils.
  def self.stub_races_ap_isnt_reporting_yet(races)
    existing_race_ids = races.map(&:id).to_set # race_day_id-party_id-state_code

    RaceDays::HardCodedData.each do |date_sym, party_races|
      race_day_id = date_sym.to_s
      party_races.each do |party_id_sym, state_code_syms|
        party_id = party_id_sym.to_s
        state_code_syms.each do |state_code_sym|
          state_code = state_code_sym.to_s
          race_id = "#{race_day_id}-#{party_id}-#{state_code}"
          next if existing_race_ids.include?(race_id)

          races << Race.new(nil, race_day_id, party_id, state_code)
        end
      end
    end
  end

  def self.load_pollster_source(copy_parties, ap_races, last_date)
    last_date_s = last_date.to_s
    wanted_race_keys = Set.new # party_id-state_code Strings
    ap_races.each do |race|
      if race.race_day_id <= last_date_s
        wanted_race_keys.add(race.party_id_and_state_code)
      end
    end

    pollster_jsons = []

    for party in copy_parties
      for chart in ApiSources.GET_pollster_primaries(party.id)
        state_code = chart[:state]

        if state_code == 'US' || wanted_race_keys.include?("#{party.id}-#{state_code}")
          slug = chart[:slug]
          pollster_jsons << ApiSources.GET_pollster_primary(slug)
        end
      end
    end

    PollsterSource.new(pollster_jsons)
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
