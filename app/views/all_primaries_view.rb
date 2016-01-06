require_relative './base_view'

class AllPrimariesView < BaseView
  attr_reader(:party)

  def initialize(party); @party = party; end

  def candidates; party.candidates; end
  def race_months; RaceDay.all.group_by{ |rd| rd.date.to_s[0...7] }.values; end
  def html_path; "2016/primaries/#{party.id}.html"; end
end
