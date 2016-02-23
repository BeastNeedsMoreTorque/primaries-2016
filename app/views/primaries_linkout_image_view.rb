require_relative './base_view'

class PrimariesLinkoutImageView < BaseView
  alias_method(:race_day, :focus_race_day)

  def output_path; '2016/primaries/linkout-image.html'; end

  def self.generate_all(database)
    self.generate_for_view(PrimariesLinkoutImageView.new(database))
  end
end
