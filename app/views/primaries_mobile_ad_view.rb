require_relative './base_view'

class PrimariesMobileAdView < BaseView
  alias_method(:race_day, :focus_race_day)

  def output_path; '2016/primaries/mobile-ad.html'; end

  def self.generate_all(database)
    self.generate_for_view(PrimariesMobileAdView.new(database))
  end
end
