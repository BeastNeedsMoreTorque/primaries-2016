require_relative './base_view'

class PrimariesAboutDelegatesView < BaseView
  def output_path; "2016/primaries/about-delegates.html"; end
  def layout; 'main'; end
  def stylesheets; [ asset_path('main.css') ]; end
  def hed; copy['primaries']['delegates-explainer']['hed']; end
  def social_description; copy['primaries']['delegates-explainer']['hed']; end
  def meta_description; social_description; end
  def suggested_tweet; social_description; end
  def body_html; render_markdown(copy['primaries']['delegates-explainer']['body_markdown']); end
  def pubbed_dt; copy['primaries']['delegates-explainer']['pubbed_dt']; end
  def updated_dt; copy['primaries']['delegates-explainer']['updated_dt']; end

  def self.generate_all(database)
    self.generate_for_view(PrimariesAboutDelegatesView.new(database))
  end
end
