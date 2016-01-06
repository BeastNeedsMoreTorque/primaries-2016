require_relative './base_view'

class AllPrimariesView < BaseView
  def output_path; "2016/primaries.html"; end
  def race_months; RaceDay.all.group_by{ |rd| rd.date.to_s[0...7] }.values; end

  def self.generate_all
    self.generate_for_view(AllPrimariesView.new)
  end
end
