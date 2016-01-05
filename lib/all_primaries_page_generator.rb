require 'haml'

require_relative './assets'
require_relative '../app/models/race_day'
require_relative '../app/models/party'
require_relative './page_generator'
require_relative './paths'
require_relative './view/html_context'

module AllPrimariesPageGenerator
  extend PageGenerator
  @template = File.read(File.expand_path('../../templates/all-primaries.html.haml', __FILE__))

  def self.generate
    Party.all.each do |party|
      self.generate_html(party)
    end
  end

  private

  class HtmlContext < ::HtmlContext
    attr_reader(:party)

    def initialize(party); @party = party; end

    def main_js_path; Assets.main_js_path; end
    def main_css_path; Assets.main_css_path; end

    def candidates; party.candidates; end
    #def votes_timestamp; election_days.map(&:timestamp).max; end
    #def delegates_timestamp; delegate_counts.timestamp; end
    def race_months; RaceDay.all.group_by{ |rd| rd.date.to_s[0...7] }.values; end

    def html_path
      "2016/primaries/#{party.id}.html"
    end
  end

  def self.generate_html(party)
    haml_engine = Haml::Engine.new(@template)
    context = HtmlContext.new(party)
    output = haml_engine.render(context)
    path = "#{Paths.Dist}/#{context.html_path}"
    write_string_to_path(output, path)
  end
end
