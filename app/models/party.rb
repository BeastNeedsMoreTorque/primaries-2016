require_relative './candidate'

Party = RubyImmutableStruct.new(:database, :id, :name, :adjective, :n_delegates_total, :n_delegates_needed) do
  def candidates
    database.candidates.select { |c| c.party_id == id.to_s }
  end
end
