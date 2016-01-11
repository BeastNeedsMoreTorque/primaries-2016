require_relative './candidate'

Party = Struct.new(:database, :id, :name, :adjective) do
  def candidates
    @candidates ||= database.candidates.select { |c| c.party_id == id.to_s }
  end
end
