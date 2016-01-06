require_relative './base_view'

class AllPrimariesView < BaseView
  attr_reader(:party)

  def initialize(party); @party = party; end

  def output_path; "2016/primaries/#{party.id}.html"; end
  def candidates; party.candidates; end
  def race_months; RaceDay.all.group_by{ |rd| rd.date.to_s[0...7] }.values; end

  def self.generate_all
    Party.all.each do |party|
      self.generate_for_view(AllPrimariesView.new(party))
    end
  end
end
