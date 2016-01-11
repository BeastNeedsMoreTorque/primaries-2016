# A person who wants to be president
Candidate = Struct.new(:database, :id, :party_id, :name, :n_delegates, :n_unpledged_delegates) do
  def party; database.parties.find(party_id); end
end
