require 'haml'

require_relative './view/html_context'

module RaceDayPageGenerator
  extend PageGenerator
  @template = File.read(File.expand_path('../../templates/race-day.html.haml', __FILE__))

  def self.generate_all
    for race_day in RaceDay.all
      generate(race_day)
    end
  end

  def self.generate(race_day)
    self.generate_html(race_day)
  end

  private

  class HtmlContext < ::HtmlContext
    attr_reader(:race_day)

    def initialize(race_day)
      @race_day = race_day
    end

    def main_js_path; Assets.main_js_path; end
    def main_css_path; Assets.main_css_path; end

    def race_months; RaceDay.all.group_by{ |rd| rd.date.to_s[0...7] }.values; end
    def states; race_day.states.sort_by(&:name); end

    def html_path
      "2016/primaries/#{race_day.id}.html"
    end
  end

  def self.generate_html(race_day)
    haml_engine = Haml::Engine.new(@template)
    context = HtmlContext.new(race_day)
    output = haml_engine.render(context)
    path = "#{Paths.Dist}/#{context.html_path}"
    write_string_to_path(output, path)
  end
end
