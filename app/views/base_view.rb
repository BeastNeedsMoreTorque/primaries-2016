require_relative '../../lib/paths'

class BaseView
  def render(options)
    if options[:partial]
      template = File.read(File.expand_path("../../templates/_#{options[:partial]}.html.haml", __FILE__))
      haml_engine = Haml::Engine.new(template)
      haml_engine.render(self)
    end
  end

  def main_js_path; Assets.main_js_path; end
  def main_css_path; Assets.main_css_path; end
end

Dir[File.dirname(__FILE__) + '/../models/*.rb'].each do |path|
  next if path =~ /database.rb$/
  require path
  basename = path.split('/').last.split('.').first
  class_name = basename.gsub(/(^|_)([^_]+)/) { $2.capitalize }
  klass = Object.const_get(class_name)
  BaseView.define_singleton_method(class_name, lambda { klass })
end
