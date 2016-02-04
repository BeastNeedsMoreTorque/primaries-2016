require 'set'

require_relative './source'

# Data from AP's election_day results.
#
# Provides:
#
# * candidate_races: id, ballot_order, n_votes, winner
# * candidate_counties: party_id, candidate_id, county_id, n_votes
# * county_fips_ints (Set of Integers)
# * county_parties: county_id, party_id, n_precincts_reporting, n_precincts_total, last_updated
# * races: id, n_votes, max_n_votes, n_precincts_reporting, n_precincts_total, last_updated
class ApElectionDaysSource < Source
  CandidateRace = RubyImmutableStruct.new(:id, :ballot_order, :n_votes, :winner)
  CandidateCounty = RubyImmutableStruct.new(:candidate_id, :fips_int, :party_id, :n_votes)
  CountyParty = RubyImmutableStruct.new(:fips_int, :party_id, :n_precincts_reporting, :n_precincts_total, :last_updated)
  Race = RubyImmutableStruct.new(:id, :n_votes, :max_n_votes, :n_precincts_reporting, :n_precincts_total, :last_updated)

  attr_reader(:county_fips_ints, :candidate_races, :candidate_counties, :county_parties, :races)

  def initialize(ap_election_day_jsons)
    @county_fips_ints = Set.new
    @candidate_races = []
    @candidate_counties = []
    @county_parties = []
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

      for reporting_unit in (race_hash[:reportingUnits] || [])
        n_precincts_reporting = reporting_unit[:precinctsReporting]
        n_precincts_total = reporting_unit[:precinctsTotal]

        if reporting_unit[:level] == 'state'
          # As described above: if this reporting_unit is set, that means AP
          # didn't give us a state_code or last_updated above, so we need to
          # set them now.
          state_code = reporting_unit[:statePostal]
          last_updated = DateTime.parse(reporting_unit[:lastUpdated])
          state_n_precincts_reporting = n_precincts_reporting
          state_n_precincts_total = n_precincts_total

          for candidate_hash in reporting_unit[:candidates]
            candidate_id = candidate_hash[:polID]
            n_votes += candidate_hash[:voteCount]
            max_n_votes = candidate_hash[:voteCount] if candidate_hash[:voteCount] > max_n_votes

            next if candidate_id.length >= 6 # unassigned, no preference, etc

            @candidate_races << CandidateRace.new("#{candidate_id}-#{race_day_id}-#{party_id}-#{state_code}", candidate_hash[:ballotOrder], candidate_hash[:voteCount], candidate_hash[:winner] == 'X')
          end
        elsif reporting_unit[:level] == 'FIPSCode'
          fips_code = reporting_unit[:fipsCode]

          fips_int = fips_code.to_i # Don't worry, Ruby won't parse '01234' as octal
          @county_fips_ints.add(fips_int)

          @county_parties << CountyParty.new(fips_int, party_id, n_precincts_reporting, n_precincts_total, last_updated)

          for candidate_hash in reporting_unit[:candidates]
            candidate_id = candidate_hash[:polID]
            next if candidate_id.length >= 6 # unassigned, no preference, etc

            @candidate_counties << CandidateCounty.new(candidate_id, fips_int, party_id, candidate_hash[:voteCount])
          end
        else
          raise "Invalid reporting unit level `#{reporting_unit[:level]}'"
        end
      end

      @races << Race.new(
        "#{race_day_id}-#{party_id}-#{state_code}",
        n_votes > 0 ? n_votes : nil,
        max_n_votes > 0 ? max_n_votes : nil,
        state_n_precincts_reporting,
        state_n_precincts_total,
        last_updated
      )
    end
  end
end
