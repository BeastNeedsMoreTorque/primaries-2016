require_relative './base_view'
require_relative '../../lib/primaries_embed_view'

class PrimariesMobileAdView < BaseView
  include PrimariesEmbedView

  def output_path; '2016/primaries/mobile-ad.html'; end

	def cur_state_code; @cur_state_code = 'IA'; end

  def cur_state; @cur_state ||= database.states.find!(cur_state_code); end

  def self.generate_all(database)
    self.generate_for_view(PrimariesMobileAdView.new(database))
  end
end
