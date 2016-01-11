require_relative './base_view'

class HomeView < BaseView
  def output_path; '2016.html'; end

  def self.generate_all(database)
    self.generate_for_view(HomeView.new(database))
  end
end
