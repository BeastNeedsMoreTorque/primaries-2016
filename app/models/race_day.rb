require 'date'
require 'set'

RaceDay = Struct.new(:database, :id, :races_codified) do
  def date; @date ||= Date.parse(id); end
  def disabled?; database.last_date && date > database.last_date; end
  def enabled?; !disabled?; end

  # States that have one or more races on this day
  def states
    @states ||= races.map(&:state).uniq.sort_by(&:name)
  end

  def races
    @races ||= database.races.select { |r| r.race_day_id == id }
  end

  def states_for_party(party)
    @states_for_party ||= {}
    @states_for_party[party.id] ||= races.select{ |r| r.party_id == party.id }.map(&:state)
  end

  def candidate_states
    @candidate_states ||= races.flat_map(&:candidate_states)
  end

  def candidate_counties
    @candidate_counties ||= races.flat_map(&:candidate_counties)
  end

  def county_parties
    @county_parties ||= races.flat_map(&:county_parties)
  end
end
