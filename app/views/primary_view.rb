require_relative './base_view'

class PrimaryView < BaseView
  attr_reader(:race)

  def initialize(race); @race = race; end
  def output_path; "2016/primaries/#{party.id}/#{state.code}.html"; end

  def party; race.party; end
  def state; race.state; end
  def html_h1; "#{state.name} #{race.race_type}"; end
  def html_title; html_h1; end

  def self.generate_all
    Race.all.each do |race|
      self.generate_for_view(PrimaryView.new(race))
    end
  end
end
