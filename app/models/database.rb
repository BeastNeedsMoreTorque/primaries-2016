require_relative './candidate_state'
require_relative './race_day'
require_relative '../../lib/ap'

module Database
  def self.load
    CandidateState.load_ap_data(AP.GET_del_super)
    RaceDay.load_ap_data(AP.GET_all_primary_election_days)
  end
end
