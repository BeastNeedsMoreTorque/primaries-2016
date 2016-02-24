require 'base64'

require_relative '../../lib/paths'
require_relative './base_view'

class PrimariesLinkoutImageView < BaseView
  alias_method(:race_day, :focus_race_day)

  def output_path; '2016/primaries/linkout-image.html'; end

  def inline_image_path(relative_path)
    bytes = IO.read("#{Paths.Assets}/images/#{relative_path}")
    "data:image/png;base64,#{Base64.strict_encode64(bytes)}"
  end

  def self.generate_all(database)
    self.generate_for_view(PrimariesLinkoutImageView.new(database))
  end
end
