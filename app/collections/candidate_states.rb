require_relative './collection_class'
require_relative '../models/candidate_state'

CandidateStates = CollectionClass.new('candidate_states', 'candidate_state', CandidateState) do
  def find_all_by_party_id_and_state_code(party_id, state_code)
    if !@by_party_id_and_state_code
      @by_party_id_and_state_code ||= all.group_by { |cs| "#{cs.party_id}-#{cs.state_code}" }
      @by_party_id_and_state_code.values.each(&:sort!)
    end
    @by_party_id_and_state_code["#{party_id}-#{state_code}"] || []
  end
end
