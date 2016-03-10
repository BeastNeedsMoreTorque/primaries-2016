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
  def meta_description; "U.S. live elections primary primaries caucus caucuses results"; end
  def social_description; "See which candidates are leading the pack for their party’s nomination, find election dates and watch live updates on election nights at The Huffington Post"; end
  def hed; 'Presidential Primaries'; end
  def updated_dt; nil; end
  def pubbed_dt; copy['primaries']['landing-page']['pubbed_dt']; end

  def focus_race_day
    @focus_race_day ||= database.race_days.all.find { |rd| rd.present? || rd.future? }
  end

  def self.generate_all(database)
    self.generate_for_view(AllPrimariesView.new(database))
  end

  def render_state_race_days_by_date
    render(partial: 'state-race-days-table', locals: {
      columns: [
        [ 'date', 'Date' ],
        [ 'state', 'State' ],
        [ 'party', 'Party' ],
        [ 'winner', 'Winner' ]
      ].map { |arr| StateRaceDaysColumn.new(*arr) },
      hide_repeats_column: 'date',
      races: races
    })
  end

  def render_state_race_days_by_state
    render(partial: 'state-race-days-table', locals: {
      columns: [
        [ 'date', 'Date' ],
        [ 'state', 'State' ],
        [ 'party', 'Party' ],
        [ 'n-delegates-int', 'Total Delegates' ],
        [ 'n-delegates-dots', 'Total Delegates' ],
        [ 'button', '' ]
      ].map { |arr| StateRaceDaysColumn.new(*arr) },
      hide_repeats_column: 'date',
      races: races
    })
  end
end
