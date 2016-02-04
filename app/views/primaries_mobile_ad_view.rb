require_relative './base_view'
require_relative '../../lib/primaries_embed_view'

class PrimariesMobileAdView < BaseView
  include PrimariesEmbedView

  def output_path; '2016/primaries/mobile-ad.html'; end

  def race_day; @race_day ||= database.race_days.find("2016-02-09"); end

  def self.generate_all(database)
    self.generate_for_view(PrimariesMobileAdView.new(database))
  end
end
