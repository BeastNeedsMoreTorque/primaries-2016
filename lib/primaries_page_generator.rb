require 'haml'

require_relative './assets'
require_relative './page_generator'
require_relative './paths'
require_relative './view/html_context'

module PrimariesPageGenerator
  extend PageGenerator
  @template = File.read(File.expand_path('../../templates/primary.html.haml', __FILE__))

  def self.generate_all
    for race_day in RaceDay.all
      for race in race_day.races
        self.generate_for_race(race)
      end
    end
  end

  # Generate all static files for the given Race.
  #
  # Generates an HTML file and a JSON file.
  def self.generate_for_race(race)
    generate_html_for_race(race)
  end

  private

  # Generate all static HTML files for
  def self.generate_html_for_race(race)
    haml_engine = Haml::Engine.new(@template)
    context = HtmlContext.new(race)
    output = haml_engine.render(context)
    path = "#{Paths.Dist}/#{context.html_path}"
    write_string_to_path(output, path)
  end

  class HtmlContext < ::HtmlContext
    attr_reader(:race)

    def initialize(race)
      @race = race
    end

    def party; race.party; end
    def state; race.state; end

    def main_js_path; Assets.main_js_path; end
    def main_css_path; Assets.main_css_path; end

    def html_h1
      "#{state.name} #{race.race_type}"
    end

    def html_title
      html_h1
    end

    def candidate_n_delegates(candidate)
      del_candidate = @delegate_counts.party_state_candidates[candidate.party][race.state_reporting_units.first.state_postal][candidate.id]
      del_candidate && del_candidate.delegates || 0
    end

    def html_path
      "2016/primaries/#{party.id}/#{state.code}.html"
    end
  end
end
