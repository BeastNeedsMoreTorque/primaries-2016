require 'date'
require 'set'

RaceDay = Struct.new(:database, :id, :races_codified) do
  def date; Date.parse(id); end

  # States that have one or more races on this day
  def states
    state_codes = Set.new(races_codified.values.flatten.map(&:to_s))
    database.states.select{ |s| state_codes.include?(s.code) }.sort_by(&:name)
  end

  def states_for_party(party)
    state_codes = (races_codified[party.id.to_sym] || []).map(&:to_s)
    database.states.select{ |s| state_codes.include?(s.code) }.sort_by(&:name)
  end
end
