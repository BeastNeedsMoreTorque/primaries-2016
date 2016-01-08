require_relative './base_view'

class HomeView < BaseView
  def output_path; '2016.html'; end

  def self.generate_all
    self.generate_for_view(HomeView.new)
  end
end
