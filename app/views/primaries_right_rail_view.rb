require_relative './base_view'

require 'date'

class PrimariesRightRailView < BaseView
  alias_method(:race_day, :focus_race_day)

  def output_path; '2016/primaries/right-rail.html'; end

  def self.generate_all(database)
    self.generate_for_view(PrimariesRightRailView.new(database))
  end
end
