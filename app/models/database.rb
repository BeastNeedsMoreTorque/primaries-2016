require 'date'
require 'time'
require 'set'

require_relative '../../lib/api_sources'
require_relative '../collections/candidates'
require_relative '../collections/candidate_county_races'
require_relative '../collections/candidate_races'
require_relative '../collections/candidate_states'
require_relative '../collections/candidate_race_days'
require_relative '../collections/candidate_race_subcounties'
require_relative '../collections/counties'
require_relative '../collections/county_races'
require_relative '../collections/race_subcounties'
require_relative '../collections/parties'
require_relative '../collections/party_race_days'
require_relative '../collections/party_states'
require_relative '../collections/races'
require_relative '../collections/race_days'
require_relative '../collections/states'
require_relative '../collections/subcounties'
require_relative '../models/candidate'
require_relative '../models/candidate_county_race'
require_relative '../models/candidate_race'
require_relative '../models/candidate_race_day'
require_relative '../models/candidate_state'
require_relative '../models/candidate_race_subcounty'
require_relative '../models/county'
require_relative '../models/county_race'
require_relative '../models/party'
require_relative '../models/party_race_day'
require_relative '../models/party_state'
require_relative '../models/race'
require_relative '../models/race_day'
require_relative '../models/race_subcounty'
require_relative '../models/state'
require_relative '../models/subcounty'
require_relative '../sources/ap_del_super_source'
require_relative '../sources/ap_election_days_source'
require_relative '../sources/copy_source'
require_relative '../sources/geo_ids_source'
require_relative '../sources/pollster_source'
require_relative '../sources/sheets_source'

# All data that goes into page rendering.
#
# Once you build a Database, nothing will change.
#
# The Database contains every Collection we use -- e.g., `candidates`, `states`
# -- plus the rendering date.
class Database
  LastDate = Date.parse(ENV['LAST_DATE'] || '2016-04-05')
  FocusRaceDayId = ENV['FOCUS_RACE_DAY_ID'] || '2016-03-15'

  CollectionNames = %w(
    candidates
    candidate_county_races
    candidate_race_subcounties
    candidate_race_days
    candidate_races
    candidate_states
    counties
    county_races
    parties
    party_race_days
    party_states
    races
    race_days
    race_subcounties
    states
  )

  attr_reader(*CollectionNames)
  attr_reader(:now)
  attr_reader(:last_date)
  attr_reader(:copy)
  attr_reader(:focus_race_day) # What we show on splash, right-rail, mobile-ad

  def initialize(copy_source, sheets_source, geo_ids_source, ap_del_super, ap_election_days, pollster_source, now, last_date, focus_race_day_id)
    @parties = load_parties(sheets_source.parties, ap_del_super.parties)
    @states = load_states(sheets_source.states)
    @party_states = load_party_states(sheets_source.party_states, pollster_source.party_states)
    @candidates = load_candidates(sheets_source.candidates, ap_del_super.candidates, pollster_source.candidates)
    @counties = load_counties(ap_election_days.county_fips_ints)
    @county_races = load_county_races(ap_election_days.county_races)
    @candidate_county_races = load_candidate_county_races(sheets_source.candidates, sheets_source.races, ap_election_days.candidate_county_races)
    @candidate_race_subcounties = load_candidate_race_subcounties(sheets_source.candidates, sheets_source.races, geo_ids_source.geo_ids, ap_election_days.candidate_race_subcounties)
    @candidate_states = load_candidate_states(sheets_source.candidates, ap_del_super.candidate_states, pollster_source.candidate_states, sheets_source.races)
    @candidate_races = load_candidate_races(sheets_source.candidates, ap_election_days.candidate_races, ap_election_days.races, sheets_source.races)
    @race_subcounties = load_race_subcounties(geo_ids_source.geo_ids, ap_election_days.race_subcounties)
    @races = load_races(sheets_source.races, copy_source.races, sheets_source.candidates, ap_election_days.races, pollster_source.candidate_states)
    @race_days = load_race_days(sheets_source.race_days, copy_source.race_days, last_date)
    @party_race_days = load_party_race_days(@parties, @race_days)
    @candidate_race_days = load_candidate_race_days(@candidates, @race_days)

    @now = now
    @last_date = last_date
    @focus_race_day = @race_days.find!(focus_race_day_id)
    @copy = copy_source.raw_data
  end

  def inspect
    "#<Database>"
  end

  def today
    now.to_datetime.new_offset('Eastern').to_date
  end

  # The "production" Database: all default Sources
  def self.load
    copy_source = default_copy_source
    geo_ids_source = default_geo_ids_source
    sheets_source = default_sheets_source
    ap_del_super = default_ap_del_super_source
    ap_election_days = default_ap_election_days_source
    pollster_source = default_pollster_source(sheets_source.parties, sheets_source.races)

    Database.new(
      copy_source,
      sheets_source,
      geo_ids_source,
      ap_del_super,
      ap_election_days,
      pollster_source,
      Time.parse(ENV['NOW'] || Time.now.utc.iso8601),
      LastDate,
      FocusRaceDayId
    )
  end

  def self.default_geo_ids_source
    GeoIdsSource.new
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

  def load_candidates(sheet_candidates, ap_del_super_candidates, pollster_candidates)
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

    all = sheet_candidates.map do |sheet_candidate|
      del_super_candidate = candidate_id_to_del_super_candidate[sheet_candidate.id]
      pollster_candidate = candidate_id_to_pollster_candidate[sheet_candidate.id]

      Candidate.new(
        self,
        sheet_candidate.id,
        sheet_candidate.party_id,
        sheet_candidate.full_name,
        sheet_candidate.last_name,
        del_super_candidate ? del_super_candidate.n_delegates : 0,
        del_super_candidate ? (del_super_candidate.n_delegates - del_super_candidate.n_unpledged_delegates) : 0,
        pollster_candidate ? pollster_candidate.poll_percent : nil,
        pollster_candidate ? pollster_candidate.sparkline : nil,
        pollster_candidate ? pollster_candidate.last_updated : nil,
        sheet_candidate.dropped_out_date_or_nil,
        sheet_candidate.in_horse_race
      )
    end

    all.sort!

    Candidates.new(all)
  end

  def load_candidate_county_races(sheets_candidates, sheets_races, ap_candidate_county_races)
    valid_candidate_race_ids = build_valid_candidate_race_ids(sheets_candidates, sheets_races)

    all = ap_candidate_county_races
      .select { |ccr| valid_candidate_race_ids.include?(ccr.candidate_race_id) }
      .map! do |ccr|
        CandidateCountyRace.new(
          self,
          ccr.candidate_id,
          ccr.fips_int,
          ccr.race_id,
          ccr.n_votes
        )
      end

    all.sort!

    CandidateCountyRaces.new(all)
  end

  def build_valid_candidate_race_ids(sheets_candidates, sheets_races)
    sheets_candidates.flat_map do |candidate|
      last_race_day_id = candidate.dropped_out_date_or_nil ? candidate.dropped_out_date_or_nil.to_s : ':' # ':' is after '9'

      sheets_races
        .select { |r| r.race_day_id <= last_race_day_id }
        .map! { |r| "#{candidate.id}-#{r.id}" }
    end.to_set
  end

  def load_candidate_race_subcounties(sheets_candidates, sheets_races, geo_ids, ap_candidate_race_subcounties)
    valid_candidate_race_ids = build_valid_candidate_race_ids(sheets_candidates, sheets_races)

    all = ap_candidate_race_subcounties
      .select { |crs| valid_candidate_race_ids.include?(crs.candidate_race_id) }
      .map! do |crs|
        geo_id = geo_ids[crs.reporting_unit_id]
        throw "Missing geo_id #{crs.reporting_unit_id} in app/sources/ap_id_to_geo_id.tsv" if geo_id.nil? || geo_id == 0

        CandidateRaceSubcounty.new(
          self,
          crs.candidate_id,
          crs.race_id,
          geo_id,
          crs.n_votes
        )
      end

    all.sort!

    CandidateRaceSubcounties.new(all)
  end

  # Creates a CandidateRace for each candidate in each race (as long as the
  # candidate has not dropped out before the race). Values can be nil.
  def load_candidate_races(sheets_candidates, ap_candidate_races, ap_races, sheets_races)
    id_to_ap_candidate_race = ap_candidate_races.each_with_object({}) { |cr, h| h[cr.id] = cr }
    id_to_ap_race = ap_races.each_with_object({}) { |r, h| h[r.id] = r }

    all = []

    for race in sheets_races
      ap_race = id_to_ap_race[race.id]
      can_calculate_percent = (!ap_race.nil? && !ap_race.n_votes.nil? && ap_race.n_votes > 0)

      for candidate in sheets_candidates
        next if candidate.party_id != race.party_id
        next if candidate.dropped_out_date_or_nil && candidate.dropped_out_date_or_nil.to_s < race.race_day_id

        id = "#{candidate.id}-#{race.id}"
        ap_candidate_race = id_to_ap_candidate_race[id]

        all << CandidateRace.new(
          self,
          candidate.id,
          race.id,
          ap_candidate_race ? ap_candidate_race.n_votes : 0,
          (can_calculate_percent && ap_candidate_race) ? (100 * ap_candidate_race.n_votes.to_f / ap_race.n_votes) : 0,
          (ap_candidate_race && ap_candidate_race.n_votes > 0) ? ap_candidate_race.n_votes == ap_race.max_n_votes : nil,
          !race.huffpost_override_winner_last_name && (ap_candidate_race ? ap_candidate_race.winner : false),
          race.huffpost_override_winner_last_name == candidate.last_name
        )
      end
    end

    all.sort!
    @candidate_races = CandidateRaces.new(all)
  end

  def load_candidate_states(sheets_candidates, del_super_candidate_states, pollster_candidate_states, sheets_races)
    valid_candidate_ids = sheets_candidates.map(&:id).to_set
    last_name_to_candidate_id = sheets_candidates.each_with_object({}) { |c, h| h[c.last_name] = c.id }
    id_to_pollster_candidate_state = pollster_candidate_states.each_with_object({}) do |pollster_candidate_state, h|
      candidate_id = last_name_to_candidate_id[pollster_candidate_state.last_name]
      if candidate_id
        id = "#{candidate_id}-#{pollster_candidate_state.state_code}"
        h[id] = pollster_candidate_state
      end
    end

    all = del_super_candidate_states
      .select { |cs| valid_candidate_ids.include?(cs.candidate_id) }
      .map! do |del_super_candidate_state|
        pollster_candidate_state = id_to_pollster_candidate_state[del_super_candidate_state.id]

        CandidateState.new(
          self,
          del_super_candidate_state.candidate_id,
          del_super_candidate_state.state_code,
          del_super_candidate_state.n_delegates,
          del_super_candidate_state.n_delegates - del_super_candidate_state.n_unpledged_delegates,
          pollster_candidate_state ? pollster_candidate_state.poll_percent : nil,
          pollster_candidate_state ? pollster_candidate_state.sparkline : nil
        )
      end

    CandidateStates.new(all)
  end

  def load_counties(ap_county_fips_ints)
    all = ap_county_fips_ints.to_a
      .map! { |fips_int| County.new(self, fips_int) }

    Counties.new(all)
  end

  def load_county_races(ap_county_races)
    all = ap_county_races
      .map do |ap_county_race|
        CountyRace.new(
          self,
          ap_county_race.fips_int,
          ap_county_race.race_id,
          ap_county_race.n_votes,
          ap_county_race.n_precincts_reporting,
          ap_county_race.n_precincts_total
        )
      end

    CountyRaces.new(all)
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

  def load_party_race_days(parties, race_days)
    all = []

    for party in parties
      for race_day in race_days
        if race_day.races.any? { |r| r.party_id == party.id }
          all << PartyRaceDay.new(self, party.id, race_day.id)
        end
      end
    end

    PartyRaceDays.new(all)
  end

  def load_candidate_race_days(candidates, race_days)
    all = []

    for candidate in candidates
      last_race_day_id = if candidate.dropped_out_date.nil?
        ':' # after '9'
      else
        candidate.dropped_out_date.to_s
      end

      for race_day in race_days
        if race_day.id <= last_race_day_id
          all << CandidateRaceDay.new(self, candidate.id, race_day.id)
        end
      end
    end

    CandidateRaceDays.new(all)
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
          sheets_party_state.n_delegates - sheets_party_state.n_unpledged_delegates,
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
        sheets_race.expect_results_time,
        copy_race ? copy_race.text : '',
        ap_race ? ap_race.n_precincts_reporting : nil,
        ap_race ? ap_race.n_precincts_total : nil,
        ap_race ? ap_race.last_updated : nil,
        sheets_race.ap_says_its_over,
        sheets_race.n_votes_th,
        sheets_race.n_votes_tooltip_th,
        sheets_race.n_votes_footnote
      )
    end

    Races.new(all)
  end

  def load_race_subcounties(geo_ids, ap_race_subcounties)
    all = ap_race_subcounties.map do |rs|
      RaceSubcounty.new(
        self,
        rs.race_id,
        geo_ids[rs.reporting_unit_id],
        rs.n_votes,
        rs.n_precincts_reporting,
        rs.n_precincts_total
      )
    end

    RaceSubcounties.new(all)
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
