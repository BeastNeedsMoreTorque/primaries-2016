require_relative './base_view'

class AllPrimariesView < BaseView
  def output_path; "2016/primaries.html"; end

  def self.generate_all
    self.generate_for_view(AllPrimariesView.new)
  end
end
