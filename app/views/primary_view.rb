require_relative './base_view'

class PrimaryView < BaseView
  attr_reader(:race)

  def initialize(race); @race = race; end
  def party; race.party; end
  def state; race.state; end
  def html_h1; "#{state.name} #{race.race_type}"; end
  def html_title; html_h1; end

  def html_path; "2016/primaries/#{party.id}/#{state.code}.html"; end
end
