require_relative '../models/candidate'
require_relative '../models/candidate_state'
require_relative '../models/party'

# Data from AP's del_super report.
#
# Provides:
#
# * candidates: id, last_name, n_delegates, n_unpledged_delegates
# * candidate_states: candidate_id, state_code, n_delegates
# * parties: id, n_delegates_total, n_delegates_needed
class ApDelSuperSource
  Candidate = RubyImmutableStruct.new(:id, :party_id, :last_name, :n_delegates, :n_unpledged_delegates)

  CandidateState = RubyImmutableStruct.new(:candidate_id, :state_code, :n_delegates) do
    attr_reader(:id)

    def after_initialize
      @id = "#{@candidate_id}-#{@state_code}"
    end
  end

  Party = RubyImmutableStruct.new(:id, :n_delegates_total, :n_delegates_needed)

  attr_reader(:candidates, :candidate_states, :parties)

  def initialize(ap_del_super_json)
    @candidates = candidates = []
    @candidate_states = candidate_states = []
    @parties = parties = []

    for del in ap_del_super_json[:del]
      party_id = del[:pId]

      parties << Party.new(party_id, del[:dVotes], del[:dNeed])

      for del_state in del[:State]
        state_code = del_state[:sId]

        next if state_code == 'UN' # "Unassigned super delegates"

        for del_candidate in del_state[:Cand]
          candidate_id = del_candidate[:cId]
          last_name = del_candidate[:cName]
          next if candidate_id.length >= 6 # unassigned, no preference, etc

          n_delegates = del_candidate[:dTot].to_i
          n_unpledged_delegates = del_candidate[:sdTot].to_i

          if state_code == 'US'
            candidates << Candidate.new(candidate_id, party_id, last_name, n_delegates, n_unpledged_delegates)
          else
            candidate_states << CandidateState.new(candidate_id, state_code, n_delegates)
          end
        end
      end
    end

    nil
  end
end
