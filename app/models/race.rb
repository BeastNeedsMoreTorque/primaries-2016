# Could almost be called PartyState. Gives the votes/delegates of a state.
Race = Struct.new(:database, :ap_id, :race_day_id, :party_id, :state_code, :race_type, :n_precincts_reporting, :n_precincts_total, :last_updated, :poll_last_updated) do
  include Comparable

  # Sort by date, then state name, then party name
  def <=>(rhs)
    c1 = date.<=>(rhs.date)
    if c1 != 0
      c1
    else
      c2 = state_name.<=>(rhs.state_name)
      if c2 != 0
        c2
      else
        party_name.<=>(rhs.party_name)
      end
    end
  end

  def party; database.parties.find!(party_id); end
  def party_name; party.name; end
  def race_day; database.race_days.find!(race_day_id); end
  def state; database.states.find!(state_code); end
  def state_name; state.name; end
  def date; race_day.date; end
  def disabled?; !race_day || race_day.disabled?; end
  def enabled?; race_day && race_day.enabled?; end
  def n_delegates; state.n_delegates(party_id); end

  def candidate_states
    @candidate_states ||= if ap_id
      database.candidate_states.find_all_by_party_id_and_state_code(party_id, state_code).sort
    else
      []
    end
  end
end
