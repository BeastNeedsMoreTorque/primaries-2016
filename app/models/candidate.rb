# A person who wants to be president
Candidate = Struct.new(:database, :id, :party_id, :full_name, :name, :n_delegates, :n_unpledged_delegates, :poll_percent, :poll_sparkline, :poll_last_update) do
  include Comparable

  def party; database.parties.find(party_id); end
  def slug; name.downcase.gsub(/[^\w]/, '-'); end

  def <=>(rhs)
    c1 = rhs.n_delegates - n_delegates
    if c1 != 0
      c1
    else
      c2 = rhs.poll_percent && poll_percent && rhs.poll_percent- poll_percent || 0
      if c2 != 0
        c2
      else
        name.<=>(rhs.name)
      end
    end
  end
end
