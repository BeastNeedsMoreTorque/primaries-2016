require_relative './base_view'

class PrimariesHorseRaceView < BaseView
  attr_reader(:party)

  def initialize(database, party)
    super(database)
    @party = party
  end

  def output_path; "2016/primaries/horse-race/#{party.id}.html"; end

  def self.generate_all(database)
    database.parties.each do |party|
      self.generate_for_view(PrimariesHorseRaceView.new(database, party))
    end
  end
end
