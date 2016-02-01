require_relative './candidate'

Party = RubyImmutableStruct.new(:database_or_nil, :id, :name, :adjective, :n_delegates_total, :n_delegates_needed) do
  def candidates
    database_or_nil && database_or_nil.candidates.select { |c| c.party_id == id.to_s }
  end
end
