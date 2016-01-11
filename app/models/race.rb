# Could almost be called PartyState. Gives the votes/delegates of a state.
Race = Struct.new(:database, :ap_id, :race_day_id, :party_id, :state_code, :race_type, :n_precincts_reporting, :n_precincts_total, :last_updated) do
  def party; database.parties.find!(party_id); end
  def race_day; database.race_days.find!(race_day_id); end
  def state; database.states.find!(state_code); end

  def candidate_states
    @candidate_states ||= if ap_id
      database.candidate_states.find_all_by_party_id_and_state_code(party_id, state_code).sort
    else
      []
    end
  end
end
