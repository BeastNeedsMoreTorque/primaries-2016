require_relative './base_view'

class PrimariesSplashView < BaseView
  alias_method(:race_day, :focus_race_day)

  def output_path; '2016/primaries/splash.html'; end

  def self.generate_all(database)
    self.generate_for_view(PrimariesSplashView.new(database))
  end

  def country_map_with_race_day_party_states_highlighted(party_id)
    state_codes = race_day.races
      .select { |race| race.party_id == party_id }
      .map(&:state_code)

    map_svg("US")
      .gsub(/ data-state-code="(#{state_codes.join('|')})"/) { " data-state-code=\"#{$1}\" class=\"today\"" }
  end
end
