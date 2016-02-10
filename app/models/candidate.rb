# A person who wants to be president
Candidate = RubyImmutableStruct.new(:database, :id, :party_id, :full_name, :name, :n_delegates, :n_unpledged_delegates, :poll_percent, :poll_sparkline, :poll_last_update, :dropped_out_date) do
  include Comparable

  def party; database.parties.find(party_id); end
  def slug; name.downcase.gsub(/[^\w]/, '-'); end

  def <=>(rhs)
    # Sort by: first, not-dropped-out; else, dropped-out date descending
    c1 = (dropped_out? ? 1.0 / dropped_out_date.mjd : -1) - (rhs.dropped_out? ? 1.0 / rhs.dropped_out_date.mjd : -1)
    if c1 != 0
      c1
    else
      # Sort by number of delegates, descending
      c2 = rhs.n_delegates - n_delegates
      if c2 != 0
        c2
      else
        # Sort by polls, descending
        c3 = (rhs.poll_percent || 0) - (poll_percent || 0)
        if c3 != 0
          c3
        else
          # Sort alphabetically
          name.<=>(rhs.name)
        end
      end
    end
  end

  def dropped_out?; !dropped_out_date.nil?; end
end
