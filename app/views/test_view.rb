require_relative './base_view'

class TestView < BaseView
  def initialize(database, slug)
    super(database)
    @slug = slug
  end

  def output_path; "2016/#{@slug}.html"; end
  def template_name; @slug; end

  def self.generate_all(database)
    self.generate_for_view(TestView.new(database, 'primaries/test-focus-race-day'))
  end
end
