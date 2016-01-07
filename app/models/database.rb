require 'date'

require_relative './candidate'
require_relative './candidate_county'
require_relative './candidate_state'
require_relative './county'
require_relative './county_party'
require_relative './race'
require_relative '../../lib/ap'

module Database
  def self.load
    Candidate.all = candidates = []
    CandidateCounty.all = candidate_counties = []
    CandidateState.all = candidate_states = []
    County.all = counties = []
    CountyParty.all = county_parties = []
    Race.all = races = []

    id_to_candidate = {}
    fips_code_to_county = {}
    ids_to_candidate_state = {}

    # Fill CandidateState (no ballot_order or n_votes) and Candidate (no name)
    for del in AP.GET_del_super[:del]
      party_id = del[:pId]
      for del_state in del[:State]
        state_code = del_state[:sId]
        next if state_code == 'UN' # "Unassigned super delegates"
        for del_candidate in del_state[:Cand]
          candidate_id = del_candidate[:cId]
          n_delegates = del_candidate[:dTot].to_i
          n_unpledged_delegates = del_candidate[:sdTot].to_i

          if state_code == 'US'
            c = Candidate.new(candidate_id, party_id, nil, n_delegates, n_unpledged_delegates)
            candidates << c
            id_to_candidate[c.id] = c
          else
            cs = CandidateState.new(candidate_id, state_code, -1, 0, n_delegates)
            candidate_states << cs
            ids_to_candidate_state[[cs.candidate_id, cs.state_code]] = cs
          end
        end
      end
    end

    for election_day in AP.GET_all_primary_election_days
      race_day_id = election_day[:electionDate]
      for race_hash in election_day[:races]
        race_id = race_hash[:raceID]
        party_id = race_hash[:party]
        race_type = race_hash[:raceType]

        race = Race.new(race_id, race_day_id, party_id, nil, race_type, nil, nil, nil)
        races << race

        for reporting_unit in race_hash[:reportingUnits]
          n_precincts_reporting = reporting_unit[:precinctsReporting]
          n_precincts_total = reporting_unit[:precinctsTotal]
          last_updated = DateTime.parse(reporting_unit[:lastUpdated])
          state_code = reporting_unit[:statePostal]

          if reporting_unit[:level] == 'state'
            race.state_code = state_code
            race.n_precincts_reporting = n_precincts_reporting
            race.n_precincts_total = n_precincts_total
            race.last_updated = last_updated

            for candidate_hash in reporting_unit[:candidates]
              candidate_id = candidate_hash[:polID]
              candidate = id_to_candidate[candidate_id]

              next if !candidate

              candidate_state = ids_to_candidate_state[[candidate.id, state_code]]

              if !candidate.name
                first_name = candidate_hash[:first]
                last_name = candidate_hash[:last]
                candidate.name ||= "#{first_name} #{last_name}".strip
              end

              if !candidate_state
                raise "Missing candidate-state pair #{candidate.id}-#{state_code}"
              end

              candidate_state.ballot_order = candidate_hash[:ballotOrder]
              candidate_state.n_votes = candidate_hash[:voteCount]
            end
          elsif reporting_unit[:level] == 'FIPSCode'
            fips_code = reporting_unit[:fipsCode]

            county = if fips_code_to_county.include?(fips_code)
              fips_code_to_county[fips_code]
            else
              t = County.new(fips_code)
              counties << t
              fips_code_to_county[fips_code] = t
            end

            county_parties << CountyParty.new(county.id, party_id, n_precincts_reporting, n_precincts_reporting, last_updated)

            for candidate_hash in reporting_unit[:candidates]
              candidate_id = candidate_hash[:polID]
              candidate = id_to_candidate[candidate_id]

              next if !candidate

              n_votes = candidate_hash[:voteCount]

              candidate_counties << CandidateCounty.new(candidate_id, county.id, n_votes)
            end
          else
            raise "Invalid reporting unit level `#{reporting_unit[:level]}'"
          end
        end
      end
    end
  end
end
