require 'haml'

require_relative './assets'
require_relative './models'
require_relative './page_generator'
require_relative './paths'
require_relative './race_days'
require_relative './view/html_context'

module AllPrimariesPageGenerator
  extend PageGenerator
  @template = File.read(File.expand_path('../../templates/all-primaries.html.haml', __FILE__))

  def self.generate(database)
    self.generate_html(database, 'Dem')
    self.generate_html(database, 'GOP')
  end

  private

  class HtmlContext < ::HtmlContext
    attr_reader(:party_id)

    def initialize(database, party_id); @database = database; @party_id = party_id; end

    def main_js_path; Assets.main_js_path; end
    def main_css_path; Assets.main_css_path; end

    def delegate_counts; @database.delegate_counts; end
    def election_days; @database.election_days; end
    def votes_timestamp; election_days.map(&:timestamp).max; end
    def delegates_timestamp; delegate_counts.timestamp; end
    def pols; @database.pols(party_id); end
    def race_months; RaceDays.group_by{ |rd| rd.date.to_s[0...7] }.values; end

    def html_path
      "2016/primaries/#{party_id}.html"
    end
  end

  def self.generate_html(database, party_id)
    haml_engine = Haml::Engine.new(@template)
    context = HtmlContext.new(database, party_id)
    output = haml_engine.render(context)
    path = "#{Paths.Dist}/#{context.html_path}"
    write_string_to_path(output, path)
  end
end
