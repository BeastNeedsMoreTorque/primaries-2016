require 'date'
require 'set'

RaceDay = Struct.new(:database, :id, :races_codified) do
  def date; @date ||= Date.parse(id); end
  def disabled?; database.last_date && date > database.last_date; end
  def enabled?; !disabled?; end

  # States that have one or more races on this day
  def states
    @states ||= begin
      state_codes = Set.new(races_codified.values.flatten.map(&:to_s))
      database.states.select{ |s| state_codes.include?(s.code) }.sort_by(&:name)
    end
  end

  def states_for_party(party)
    @states_for_party ||= {}
    @states_for_party[party.id] ||= begin
      state_codes = (races_codified[party.id.to_sym] || []).map(&:to_s)
      database.states.select{ |s| state_codes.include?(s.code) }.sort_by(&:name)
    end
  end
end
