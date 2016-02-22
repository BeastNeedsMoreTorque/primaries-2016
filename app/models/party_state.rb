PartyState = RubyImmutableStruct.new(:database, :party_id, :state_code, :n_delegates, :n_pledged_delegates, :pollster_slug, :pollster_last_updated) do
  attr_reader(:id)

  def after_initialize
    @id = "#{@party_id}-#{@state_code}"
  end
end
