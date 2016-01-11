require_relative './base_view'
require_relative '../../lib/primaries_embed_view'

class PrimariesMobileAdView < BaseView
  include PrimariesEmbedView

  def output_path; '2016/primaries/mobile-ad.html'; end

  def leading_democrat
    Party.find(:Dem).candidates.max_by(&:n_delegates)
  end

  def leading_republican
    Party.find(:GOP).candidates.max_by(&:n_delegates)
  end

  def self.generate_all
    self.generate_for_view(PrimariesMobileAdView.new)
  end
end
