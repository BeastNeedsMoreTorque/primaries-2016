PartyState = RubyImmutableStruct.new(:database_or_nil, :party_id, :state_code, :n_delegates, :pollster_slug, :pollster_last_updated) do
  attr_reader(:id)

  def after_initialize
    @id = "#{@party_id}-#{@state_code}"
  end
end
