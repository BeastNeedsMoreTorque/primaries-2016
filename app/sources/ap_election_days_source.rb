require 'set'

require_relative './source'

# Data from AP's election_day results.
#
# Note that we write "ID" directly. Most of the Arrays returned contain
# "join"-type data. The ID of a CandidateRace will be
# "#{candidate_id}-#{race_id}". The rules:
#
# * Each capitalized thing means another sub-ID.
# * Joins are always in alphabetical order.
#   It's CountyRace, but RaceSubcounty.
#
# Provides:
#
# * candidate_races: id, n_votes, winner
# * candidate_county_races: id, fips_int, party_id, n_votes
# * candidate_subcounty_races: id, n_votes
# * county_fips_ints (Set of Integers)
# * county_races: id, n_votes, n_precincts_reporting, n_precincts_total
# * subcounty_reporting_unit_ids (Set of Integers)
# * race_subcounties: id, race_id, reporting_unit_id, n_votes, n_precincts_reporting, n_precincts_total
# * races: id, party_id, state_code, n_votes, max_n_votes, n_precincts_reporting, n_precincts_total, last_updated
class ApElectionDaysSource < Source
  CandidateRace = RubyImmutableStruct.new(:id, :candidate_id, :n_votes, :winner)
  CandidateCountyRace = RubyImmutableStruct.new(:id, :n_votes)
  CandidateRaceSubcounty = RubyImmutableStruct.new(:id, :n_votes)
  CountyRace = RubyImmutableStruct.new(:fips_int, :race_id, :n_votes, :n_precincts_reporting, :n_precincts_total)
  RaceSubcounty = RubyImmutableStruct.new(:id, :n_votes, :n_precincts_reporting, :n_precincts_total)
  Race = RubyImmutableStruct.new(:id, :party_id, :state_code, :n_votes, :max_n_votes, :n_precincts_reporting, :n_precincts_total, :last_updated)

  attr_reader(
    :county_fips_ints,
    :subcounty_reporting_unit_ids,
    :candidate_races,
    :candidate_county_races,
    :candidate_subcounty_races,
    :county_races,
    :race_subcounties,
    :races
  )

  def initialize(ap_election_day_jsons)
    @county_fips_ints = Set.new
    @subcounty_reporting_unit_ids = Set.new
    @candidate_races = []
    @candidate_county_races = []
    @candidate_race_subcounties = []
    @county_races = []
    @race_subcounties = []
    @races = []

    for ap_election_day_json in ap_election_day_jsons
      add(ap_election_day_json)
    end
  end

  private

  def add(ap_election_day_json)
    race_day_id = ap_election_day_json[:electionDate]

    for race_hash in ap_election_day_json[:races]
      party_id = race_hash[:party]
      state_n_precincts_reporting = nil # if there are :reportingUnits, they'll set this
      state_n_precincts_total = nil # if there are :reportingUnits, they'll set this
      n_votes = 0
      max_n_votes = 0

      # If the race is in the future, AP will put a :statePostal here.
      # If the race is today or in the past, AP will omit this :statePostal
      # and add one to the state :reportingUnit instead
      state_code = race_hash[:statePostal]

      # If the race is in the future, AP will have no :reportingUnits, and it
      # will put the :lastUpdated in the main hash. If the race is today, AP
      # will omit this :lastUpdated; we'll use the :lastUpdated on the state
      # :reportingUnit instead.
      last_updated = race_hash[:lastUpdated] ? DateTime.parse(race_hash[:lastUpdated]) : nil

      race_id = "#{race_day_id}-#{party_id}-#{state_code}" # We may rewrite this

      for reporting_unit in (race_hash[:reportingUnits] || [])
        n_precincts_reporting = reporting_unit[:precinctsReporting]
        n_precincts_total = reporting_unit[:precinctsTotal]

        if !state_code
          state_code = reporting_unit[:statePostal]
          race_id = "#{race_day_id}-#{party_id}-#{state_code}" # Rewritten
        end

        if reporting_unit[:level] == 'state'
          # As described above: if this reporting_unit is set, that means AP
          # didn't give us a last_updated above, so we need to set it now.
          last_updated = DateTime.parse(reporting_unit[:lastUpdated])
          state_n_precincts_reporting = n_precincts_reporting
          state_n_precincts_total = n_precincts_total

          for candidate_hash in reporting_unit[:candidates]
            candidate_id = candidate_hash[:polID]

            n_votes += candidate_hash[:voteCount]
            max_n_votes = candidate_hash[:voteCount] if candidate_hash[:voteCount] > max_n_votes

            next if candidate_id.length >= 6 # unassigned, no preference, etc

            @candidate_races << CandidateRace.new(
              "#{candidate_id}-#{race_id}",
              candidate_id,
              candidate_hash[:voteCount],
              candidate_hash[:winner] == 'X'
            )
          end
        elsif reporting_unit[:level] == 'FIPSCode'
          fips_code = reporting_unit[:fipsCode]

          fips_int = fips_code.to_i # Don't worry, Ruby won't parse '01234' as octal
          @county_fips_ints.add(fips_int)
          n_county_votes = 0

          for candidate_hash in reporting_unit[:candidates]
            candidate_id = candidate_hash[:polID]
            n_county_votes += candidate_hash[:voteCount]

            next if candidate_id.length >= 6 # unassigned, no preference, etc

            @candidate_county_races << CandidateCountyRace.new(
              "#{candidate_id}-#{fips_int}-#{race_id}",
              candidate_hash[:voteCount]
            )
          end

          @county_races << CountyRace.new(
            fips_int,
            race_id,
            n_county_votes,
            n_precincts_reporting,
            n_precincts_total
          )
        elsif reporting_unit[:level] == 'subunit'
          reporting_unit_id = reporting_unit[:reportingunitID].to_i # Don't worry, Ruby won't parse '01234' as octal
          @subcounty_reporting_unit_ids.add(reporting_unit_id)

          n_subcounty_votes = 0

          for candidate_hash in reporting_unit[:candidates]
            candidate_id = candidate_hash[:polID]
            n_subcounty_votes += candidate_hash[:voteCount]

            next if candidate_id.length >= 6 # unassigned, no preference, etc

            @candidate_race_subcounties << CandidateRaceSubcounty.new(
              "#{candidate_id}-#{reporting_unit_id}-#{race_id}",
              candidate_hash[:voteCount]
            )
          end

          @race_subcounties << RaceSubcounty.new(
            "#{race_id}-#{reporting_unit_id}",
            n_subcounty_votes,
            n_precincts_reporting,
            n_precincts_total
          )
        else
          raise "Unexpected reporting_unit level: `#{reporting_unit[:level]}`"
        end
      end

      @races << Race.new(
        race_id,
        party_id,
        state_code,
        n_votes > 0 ? n_votes : nil,
        max_n_votes > 0 ? max_n_votes : nil,
        state_n_precincts_reporting,
        state_n_precincts_total,
        last_updated
      )
    end
  end
end
