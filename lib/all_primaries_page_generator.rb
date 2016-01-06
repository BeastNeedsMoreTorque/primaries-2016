require_relative '../app/models/party'
require_relative '../app/views/all_primaries_view'
require_relative './page_generator'

module AllPrimariesPageGenerator
  extend PageGenerator

  def self.generate
    template = File.read(File.expand_path('../../templates/all-primaries.html.haml', __FILE__))
    Party.all.each do |party|
      self.generate_html(template, AllPrimariesView.new(party))
    end
  end
end
