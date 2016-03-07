require_relative './candidate'

Party = RubyImmutableStruct.new(:database, :id, :name, :adjective, :n_delegates_total, :n_delegates_needed) do
  def candidates
    database.candidates.select { |c| c.party_id == id.to_s }
  end

  def abbreviation
    name[0]
  end

  def candidates
    database.candidates.find_all_by_party_id(id)
  end

  def party_race_days
    database.party_race_days.find_all_by_party_id(id)
  end

  def party_race_days_with_pledged_delegates
    party_race_days.select { |prd| prd.n_pledged_delegates_with_candidates > 0 }
  end

  def horse_race_data
    {
      n_delegates: n_delegates_total,
      n_delegates_needed: n_delegates_needed,
      race_days: party_race_days_with_pledged_delegates.map(&:horse_race_data)
    }
  end
end
