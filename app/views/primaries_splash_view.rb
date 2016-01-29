require_relative './base_view'
require_relative '../../lib/primaries_embed_view'

class PrimariesSplashView < BaseView
  include PrimariesEmbedView

  def output_path; '2016/primaries/splash.html'; end

  def race_day; @race_day ||= database.race_days.find("2016-02-01"); end

  def self.generate_all(database)
    self.generate_for_view(PrimariesSplashView.new(database))
  end
end
