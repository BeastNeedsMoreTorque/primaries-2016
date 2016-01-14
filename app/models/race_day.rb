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
end
