require 'date'
require 'set'

require_relative '../../lib/api_sources'
require_relative '../collections/candidates'
require_relative '../collections/candidate_counties'
require_relative '../collections/candidate_states'
require_relative '../collections/counties'
require_relative '../collections/county_parties'
require_relative '../collections/parties'
require_relative '../collections/party_states'
require_relative '../collections/races'
require_relative '../collections/race_days'
require_relative '../collections/states'
require_relative '../models/candidate'
require_relative '../models/candidate_county'
require_relative '../models/candidate_state'
require_relative '../models/county'
require_relative '../models/county_party'
require_relative '../models/party'
require_relative '../models/party_state'
require_relative '../models/race'
require_relative '../models/race_day'
require_relative '../models/state'
require_relative '../sources/ap_del_super_source'
require_relative '../sources/ap_election_days_source'
require_relative '../sources/copy_source'
require_relative '../sources/pollster_source'
require_relative '../sources/sheets_source'

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
    party_states
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

  def initialize(copy_source, sheets_source, ap_del_super, ap_election_days, pollster_source, today, last_date)
    @parties = load_parties(sheets_source.parties, ap_del_super.parties)
    @states = load_states(sheets_source.states)
    @party_states = load_party_states(sheets_source.party_states, pollster_source.party_states)
    @candidates = load_candidates(sheets_source.candidates, ap_del_super.candidates, pollster_source.candidates)
    @counties = load_counties(ap_election_days.county_fips_ints)
    @county_parties = load_county_parties(ap_election_days.county_parties)
    @candidate_counties = load_candidate_counties(sheets_source.candidates, ap_election_days.candidate_counties)
    @candidate_states = load_candidate_states(sheets_source.candidates, ap_election_days.candidate_states, ap_del_super.candidate_states, pollster_source.candidate_states, sheets_source.races)
    @races = load_races(sheets_source.races, copy_source.races, sheets_source.candidates, ap_election_days.races, pollster_source.candidate_states)
    @race_days = load_race_days(sheets_source.race_days, copy_source.race_days, LastDate)

    @today = today
    @last_date = last_date
    @copy = copy_source.raw_data
  end

  def inspect
    "#<Database>"
  end

  # The "production" Database: all default Sources
  def self.load
    copy_source = default_copy_source
    sheets_source = default_sheets_source
    ap_del_super = default_ap_del_super_source
    ap_election_days = default_ap_election_days_source
    pollster_source = default_pollster_source(sheets_source.parties, sheets_source.races)

    Database.new(
      copy_source,
      sheets_source,
      ap_del_super,
      ap_election_days,
      pollster_source,
      Date.today,
      LastDate
    )
  end

  def self.default_copy_source
    CopySource.new(IO.read("#{Paths.StaticData}/copy.archieml"))
  end

  def self.default_sheets_source
    SheetsSource.new(
      IO.read("#{Paths.StaticData}/candidates.tsv"),
      IO.read("#{Paths.StaticData}/parties.tsv"),
      IO.read("#{Paths.StaticData}/races.tsv"),
      IO.read("#{Paths.StaticData}/race_days.tsv"),
      IO.read("#{Paths.StaticData}/states.tsv")
    )
  end

  def self.default_ap_del_super_source
    ApDelSuperSource.new(ApiSources.GET_del_super)
  end

  def self.default_ap_election_days_source
    ApElectionDaysSource.new(ApiSources.GET_all_primary_election_days)
  end

  def self.default_pollster_source(parties, races)
    load_pollster_source(parties, races, LastDate)
  end

  def load_candidates(copy_candidates, ap_del_super_candidates, pollster_candidates)
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

    candidates = copy_candidates.map do |copy_candidate|
      del_super_candidate = candidate_id_to_del_super_candidate[copy_candidate.id]
      pollster_candidate = candidate_id_to_pollster_candidate[copy_candidate.id]

      Candidate.new(
        self,
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

    Candidates.new(candidates)
  end

  def load_candidate_counties(copy_candidates, ap_candidate_counties)
    valid_candidate_ids = Set.new(copy_candidates.map(&:id))

    all = ap_candidate_counties
      .select { |candidate_county| valid_candidate_ids.include?(candidate_county.candidate_id) }
      .map! { |cc| CandidateCounty.new(self, cc.party_id, cc.candidate_id, cc.fips_int, cc.n_votes) }

    CandidateCounties.new(all)
  end

  def load_candidate_states(sheets_candidates, ap_candidate_states, del_super_candidate_states, pollster_candidate_states, sheets_races)
    id_to_candidate = sheets_candidates.each_with_object({}) { |c, h| h[c.id] = c }

    id_to_ap_candidate_state = ap_candidate_states.each_with_object({}) { |cs, h| h[cs.id] = cs }

    last_name_to_candidate_id = sheets_candidates.each_with_object({}) { |c, h| h[c.last_name] = c.id }
    id_to_pollster_candidate_state = pollster_candidate_states.each_with_object({}) do |pollster_candidate_state, h|
      candidate_id = last_name_to_candidate_id[pollster_candidate_state.last_name]
      if candidate_id
        id = "#{candidate_id}-#{pollster_candidate_state.state_code}"
        h[id] = pollster_candidate_state
      end
    end

    candidate_id_to_party_id = sheets_candidates.each_with_object({}) { |c, h| h[c.id] = c.party_id }

    party_state_id_to_first_race_day_id = sheets_races.each_with_object({}) do |race, h|
      # Assume races are in alphabetical order; this loop will only save the first race for each party_state
      h[race.party_state_id] ||= race.race_day_id
    end

    all = del_super_candidate_states
      .select do |candidate_state|
        candidate = id_to_candidate[candidate_state.candidate_id]
        if !candidate
          false
        else
          dropped_out_date = candidate.dropped_out_date_or_nil
          if !dropped_out_date
            true
          else
            dropped_out_date_s = dropped_out_date.to_s
            party_state_id = "#{candidate.party_id}-#{candidate_state.state_code}"
            race_day_id = party_state_id_to_first_race_day_id[party_state_id]
            if !race_day_id # GOP-CO has no race
              # TODO revisit this logic?
              false # the candidate dropped out and won't get any Colorado delegates
            else
              dropped_out_date_s >= race_day_id
            end
          end
        end
      end
      .map! do |del_super_candidate_state|
        ap_candidate_state = id_to_ap_candidate_state[del_super_candidate_state.id]
        pollster_candidate_state = id_to_pollster_candidate_state[del_super_candidate_state.id]

        CandidateState.new(
          self,
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

    CandidateStates.new(all)
  end

  def load_counties(ap_county_fips_ints)
    all = ap_county_fips_ints.to_a
      .map! { |fips_int| County.new(self, fips_int) }

    Counties.new(all)
  end

  def load_county_parties(ap_county_parties)
    all = ap_county_parties
      .map! do |ap_county_party|
        CountyParty.new(
          self,
          ap_county_party.fips_int,
          ap_county_party.party_id,
          ap_county_party.n_precincts_reporting,
          ap_county_party.n_precincts_total,
          ap_county_party.last_updated
        )
      end

    CountyParties.new(all)
  end

  def load_parties(copy_parties, del_super_parties)
    id_to_del_super_party = del_super_parties.each_with_object({}) { |p, h| h[p.id] = p }

    all = copy_parties.map do |copy_party|
      del_super_party = id_to_del_super_party[copy_party.id]
      Party.new(
        self,
        copy_party.id,
        copy_party.name,
        copy_party.adjective,
        del_super_party.n_delegates_total,
        del_super_party.n_delegates_needed
      )
    end

    Parties.new(all)
  end

  def load_party_states(sheets_party_states, pollster_party_states)
    id_to_pollster_party_state = pollster_party_states.each_with_object({}) { |ps, h| h[ps.id] = ps }

    all = sheets_party_states
      .map do |sheets_party_state|
        pollster_party_state = id_to_pollster_party_state[sheets_party_state.id]
        PartyState.new(
          self,
          sheets_party_state.party_id,
          sheets_party_state.state_code,
          sheets_party_state.n_delegates,
          pollster_party_state ? pollster_party_state.slug : nil,
          pollster_party_state ? pollster_party_state.last_updated : nil
        )
      end

    PartyStates.new(all)
  end

  def load_races(sheets_races, copy_races, sheets_candidates, ap_races, pollster_candidate_states)
    id_to_ap_race = ap_races.each_with_object({}) { |r, h| h[r.id] = r }
    id_to_copy_race = copy_races.each_with_object({}) { |r, h| h[r.id] = r }

    all = sheets_races.map do |sheets_race|
      ap_race = id_to_ap_race[sheets_race.id]
      copy_race = id_to_copy_race[sheets_race.id]

      Race.new(
        self,
        sheets_race.race_day_id,
        sheets_race.party_id,
        sheets_race.state_code,
        sheets_race.race_type,
        copy_race ? copy_race.text : '',
        ap_race ? ap_race.n_precincts_reporting : nil,
        ap_race ? ap_race.n_precincts_total : nil,
        ap_race ? ap_race.last_updated : nil,
        sheets_race.ap_says_its_over
      )
    end

    Races.new(all)
  end

  def load_race_days(sheets_race_days, copy_race_days, last_date)
    last_date_s = last_date.to_s

    id_to_copy_race_day = copy_race_days.each_with_object({}) { |rd, h| h[rd.id] = rd }

    all = sheets_race_days.map do |race_day|
      copy_race_day = id_to_copy_race_day[race_day.id]

      RaceDay.new(
        self,
        race_day.id,
        race_day.id <= last_date_s,
        copy_race_day ? copy_race_day.title : nil,
        copy_race_day ? copy_race_day.body : nil,
        copy_race_day ? copy_race_day.tweet : nil,
        copy_race_day ? copy_race_day.pubbed_dt : nil,
        copy_race_day ? copy_race_day.updated_dt_or_nil : nil
      )
    end

    RaceDays.new(all)
  end

  def load_states(sheets_states)
    all = sheets_states.map do |sheets_state|
      State.new(
        self,
        sheets_state.fips_int,
        sheets_state.state_code,
        sheets_state.abbreviation,
        sheets_state.name
      )
    end

    States.new(all)
  end

  def self.load_pollster_source(copy_parties, sheets_races, last_date)
    last_date_s = last_date.to_s
    wanted_party_state_ids = Set.new # party_id-state_code Strings
    sheets_races.each do |race|
      if race.race_day_id <= last_date_s
        wanted_party_state_ids.add(race.party_state_id)
      end
    end

    pollster_jsons = []

    for party in copy_parties
      for chart in ApiSources.GET_pollster_primaries(party.id)
        state_code = chart[:state]

        if state_code == 'US' || wanted_party_state_ids.include?("#{party.id}-#{state_code}")
          slug = chart[:slug]
          pollster_jsons << ApiSources.GET_pollster_primary(slug)
        end
      end
    end

    PollsterSource.new(pollster_jsons)
  end
end
