# Vote counts for a Candidate in a Race
#
# See also CandidateState. They aren't the same thing: there can be two races
# in one state with the same candidate.
CandidateRace = RubyImmutableStruct.new(:database, :candidate_id, :race_id, :n_votes, :percent_vote, :leader, :ap_says_winner, :huffpost_says_winner) do
  include Comparable

  attr_reader(:id, :candidate, :candidate_race_day_id, :candidate_state, :party_id, :race_day_id, :state_code, :state)

  def after_initialize
    @id = "#{@candidate_id}-#{@race_id}"
    @candidate_race_day_id = "#{@candidate_id}-#{@race_id[0...10]}"
    @party_id = @race_id[11...14]
    @race_day_id = @race_id[0...10]
    @state_code = @race_id[-2..-1]
    @state = database.states.find!(@state_code)
    @candidate = database.candidates.find!(@candidate_id)
    @candidate_state = database.candidate_states.find("#{@candidate_id}-#{@state_code}") # may be nil
  end

  def n_delegates; @candidate_state ? @candidate_state.n_delegates : 0; end
  def n_pledged_delegates; @candidate_state ? @candidate_state.n_pledged_delegates : 0; end
  def poll_sparkline; @candidate_state ? @candidate_state.poll_sparkline : nil; end
  def poll_percent; @candidate_state ? @candidate_state.poll_percent : nil; end
  def candidate_last_name; @candidate.name; end
  def candidate_slug; @candidate.slug; end
  def state_name; @state.name; end
  def race; database.races.find!(@race_id); end
  def race_href; race.href; end
  def winner?; ap_says_winner || huffpost_says_winner; end
  def leader?; @leader; end

  # A String of HTML classes.
  #
  # Possible return values:
  #
  # * "leader"
  # * "leader winner"
  # * ""
  def html_winner_leader_classes
    if winner?
      "leader winner"
    elsif leader?
      "leader"
    else
      ""
    end
  end

  def <=>(rhs)
    # Sort by race_day ID first. We have to do it at some point.
    x = race_day_id <=> rhs.race_day_id
    return x if x != 0

    # Next, by party. We have to do it at some point.
    x = party_id <=> rhs.party_id
    return x if x != 0

    # Sort by state next. State *name*, not state *code*: we need sorted state
    # names in delegate-summary.
    x = state_name <=> rhs.state_name
    return x if x != 0

    # Same race? The one with most votes comes on top
    x = (rhs.n_votes || 0) <=> (n_votes || 0)
    return x if x != 0

    # Otherwise, the polling leader comes on top
    x = (rhs.poll_percent || 0) <=> (poll_percent || 0)
    return x if x != 0

    # Last resort: sort by name
    return candidate_last_name <=> rhs.candidate_last_name
  end
end
