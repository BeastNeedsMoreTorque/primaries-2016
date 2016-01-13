require_relative './base_view'
require_relative '../../lib/primaries_embed_view'

class PrimariesRightRailView < BaseView
  include PrimariesEmbedView

  def output_path; '2016/primaries/right-rail.html'; end

  def dem_candidates; database.candidates.select{ |cd| cd.party_id == 'GOP'}; end
  def gop_candidates; database.candidates.select{ |cd| cd.party_id == 'GOP'}; end
  def state_iowa; database.states.select{ |s| s.code == 'IA' }; end

  def self.generate_all(database)
    self.generate_for_view(PrimariesRightRailView.new(database))
  end
end
