require_relative './base_view'
require_relative '../../lib/primaries_embed_view'

class PrimariesSplashView < BaseView
  include PrimariesEmbedView

  def output_path; '2016/primaries/splash.html'; end

  def self.generate_all(database)
    self.generate_for_view(PrimariesSplashView.new(database))
  end
end
