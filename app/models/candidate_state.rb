# Delegate counts for a Candidate in a State.
#
# If `state` is nil, this is the country-wide result.
#
# This is where we parse the del_super result from AP's API.
class CandidateState
  def self.load_ap_data(del_super)
    @all_hash = {} # party_id -> state_code -> candidate_id -> CandidateState
    for del in del_super[:del]
      party_id = del[:pId]
      party_hash = (@all_hash[party_id] ||= {})
      for del_state in del[:State]
        state_code = del_state[:sId]
        next if [ 'DA', 'UN' ].include?(state_code) # Dunno what these mean
        state_hash = (party_hash[state_code] ||= {})
        for del_candidate in del_state[:Cand]
          candidate_id = del_candidate[:cId]
          n_delegates = del_candidate[:dTot].to_i
          n_unpledged_delegates = del_candidate[:sdTot].to_i

          cs = CandidateState.new(candidate_id, state_code, party_id, n_delegates, n_unpledged_delegates)
          state_hash[candidate_id] = cs
        end
      end
    end
  end

  attr_reader(:candidate_id, :state_code, :party_id, :n_delegates, :n_unpledged_delegates)

  def initialize(candidate_id, state_code, party_id, n_delegates, n_unpledged_delegates)
    @candidate_id = candidate_id
    @state_code = state_code
    @party_id = party_id
    @n_delegates = n_delegates
    @n_unpledged_delegates = n_unpledged_delegates
  end

  def candidate; Candidate.find_by_id(@candidate_id); end
  def party; Party.find_by_id(@party_id); end
  def state
    if @state_code == 'US'
      nil
    else
      @state ||= State.find_by_code(@state_code)
    end
  end

  def self.by_candidate_and_state(candidate, state)
    @by_candidate_and_state ||= all.map{ |cs| [ [ cs.candidate, cs.state ], cs ] }.to_h
    @by_candidate_and_state.fetch([ candidate, state ])
  end

  def self.all
    @all ||= @all_hash.values.flat_map(&:values).flat_map(&:values)
  end
end
