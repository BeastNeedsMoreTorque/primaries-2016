# A person who wants to be president
Candidate = Struct.new(:database, :id, :party_id, :full_name, :name, :n_delegates, :n_unpledged_delegates, :poll_percent) do
  def party; database.parties.find(party_id); end
  def slug; name.downcase.gsub(/[^\w]/, '-'); end
end
