require_relative './base_view'

class SitemapView < BaseView
  def output_path; '2016/primaries/sitemap.txt'; end

  def self.generate_for_view(view)
    urls = []
    urls << '/2016/primaries'

    for race_day in view.database.race_days
      urls << race_day.href
    end

    urls << '/2016/primaries/about-delegates'

    urls.map! { |url| "http://elections.huffingtonpost.com#{url}" }

    self.write_contents("#{Paths.Dist}/#{view.output_path}", urls.join("\n"))
  end

  def self.generate_all(database)
    self.generate_for_view(SitemapView.new(database))
  end
end
