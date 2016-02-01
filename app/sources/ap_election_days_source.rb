require 'set'

require_relative './source'

require_relative '../models/candidate'
require_relative '../models/candidate_county'
require_relative '../models/candidate_state'
require_relative '../models/county'
require_relative '../models/county_party'
require_relative '../models/race'

# Data from AP's election_day results.
#
# Provides:
#
# * candidates: id, party_id, name
# * candidate_states: candidate_id, state_code, ballot_order, n_votes
# * candidate_counties: party_id, candidate_id, county_id, n_votes
# * counties: fips_int
# * county_parties: county_id, party_id, n_precincts_reporting, n_precincts_total, last_updated
# * races: ap_id, race_day_id, party_id, state_code, race_type, n_precincts_reporting, n_precincts_total, last_updated
class ApElectionDaysSource < Source
  def initialize(ap_election_day_jsons)
    @county_fips_ints = Set.new
    @candidate_states = []
    @candidate_counties = []
    @county_parties = []
    @races = []

    for ap_election_day_json in ap_election_day_jsons
      add(ap_election_day_json)
    end

    @counties = @county_fips_ints.to_a.map { |fips_int| County.new(nil, fips_int) }
  end

  private

  def add(ap_election_day_json)
    race_day_id = ap_election_day_json[:electionDate]

    for race_hash in ap_election_day_json[:races]
      race_id = race_hash[:raceID]
      party_id = race_hash[:party]
      race_type = race_hash[:raceType]
      state_n_precincts_reporting = nil # if there are :reportingUnits, they'll set this
      state_n_precincts_total = nil # if there are :reportingUnits, they'll set this

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
            next if candidate_id.length >= 6 # unassigned, no preference, etc

            @candidate_states << CandidateState.new(nil, candidate_id, state_code, candidate_hash[:ballotOrder], candidate_hash[:voteCount])
          end
        elsif reporting_unit[:level] == 'FIPSCode'
          fips_code = reporting_unit[:fipsCode]

          county_id = fips_code.to_i # Don't worry, Ruby won't parse '01234' as octal
          @county_fips_ints.add(county_id)

          @county_parties << CountyParty.new(nil, county_id, party_id, n_precincts_reporting, n_precincts_total, last_updated)

          for candidate_hash in reporting_unit[:candidates]
            candidate_id = candidate_hash[:polID]
            next if candidate_id.length >= 6 # unassigned, no preference, etc

            n_votes = candidate_hash[:voteCount]

            @candidate_counties << CandidateCounty.new(nil, party_id, candidate_id, county_id, n_votes)
          end
        else
          raise "Invalid reporting unit level `#{reporting_unit[:level]}'"
        end
      end

      @races << Race.new(nil, race_id, race_day_id, party_id, state_code, race_type, state_n_precincts_reporting, state_n_precincts_total, last_updated)
    end
  end
end
