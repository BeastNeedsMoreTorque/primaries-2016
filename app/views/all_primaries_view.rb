require_relative './base_view'

require_relative '../helpers/dot_group_helper'
require_relative '../models/race_day'

require_relative '../helpers/dot_group_helper'

class AllPrimariesView < BaseView
  include DotGroupHelper

  def output_path; "2016/primaries.html"; end
  def layout; 'main'; end
  def stylesheets; [ asset_path('main.css') ]; end
  def hed; copy['primaries']['landing-page']['hed']; end
  def body; copy['primaries']['landing-page']['body']; end

  def suggested_tweet; "Check HuffPost's 2016 primaries dashboard to find dates and watch live updates on election nights"; end
  def meta_description; "U.S. live elections primary primaries caucus caucuses results horse race"; end
  def social_description; "See which candidates are leading the pack for their party’s nomination, find election dates and watch live updates on election nights at The Huffington Post"; end
  def hed; 'Presidential Primaries'; end
  def pubbed_dt; copy['primaries']['landing-page']['pubbed_dt']; end
  def updated_dt; copy['primaries']['landing-page']['updated_dt']; end

  def focus_race_day
    @focus_race_day ||= database.race_days.all.find { |rd| rd.present? || rd.future? }
  end

  def self.generate_all(database)
    self.generate_for_view(AllPrimariesView.new(database))
  end

  def render_state_race_days_past
    render(partial: 'state-race-days-past', locals: {
      hide_repeats_column: 'date',
      race_days: database.race_days.select(&:past?)
    })
  end

  def render_state_race_days_future
    render(partial: 'state-race-days-future', locals: {
      hide_repeats_column: 'date',
      race_days: database.race_days.select(&:future?)
    })
  end

  # The stuff within a d="..." in an SVG <path> for the given state
  def state_svg_outline_path(state_code)
    svg = map_svg("states/tiny/#{state_code}")
    svg =~ /<path class="state" d="([^"]+)"/
    $1
  end
end
