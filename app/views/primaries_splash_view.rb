require_relative './base_view'

class PrimariesSplashView < BaseView
  alias_method(:race_day, :focus_race_day)

  def output_path; '2016/primaries/splash.html'; end

  def self.generate_all(database)
    self.generate_for_view(PrimariesSplashView.new(database))
  end
end
