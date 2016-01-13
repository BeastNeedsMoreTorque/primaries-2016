require_relative './base_view'

class AllPrimariesView < BaseView
  def output_path; "2016/primaries.html"; end

  def dem_candidates; database.candidates.select{ |cd| cd.party_id == 'Dem'}; end
  def gop_candidates; database.candidates.select{ |cd| cd.party_id == 'GOP'}; end

  def self.generate_all(database)
    self.generate_for_view(AllPrimariesView.new(database))
  end
end
