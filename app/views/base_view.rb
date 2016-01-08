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
  def race_months; RaceDay.all.group_by{ |rd| rd.date.to_s[0...7] }.values; end
  def party; Party.all; end

  def template
    @template ||= File.read(File.expand_path("../../templates/#{template_name}.html.haml", __FILE__))
  end

  protected

  def self.generate_for_view(view)
    path = "#{Paths.Dist}/#{view.output_path}"
    $logger.debug("Generating #{path}")
    haml_engine = Haml::Engine.new(view.template)
    output = haml_engine.render(view)
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, 'w') { |f| f.write(output) }
  end

  def template_name
    t = self.class.name.gsub(/([A-Z])/) { "-#{$1.downcase}" }
    t[1..-6]
  end
end

Dir[File.dirname(__FILE__) + '/../models/*.rb'].each do |path|
  next if path =~ /database.rb$/
  require path
  basename = path.split('/').last.split('.').first
  class_name = basename.gsub(/(^|_)([^_]+)/) { $2.capitalize }
  klass = Object.const_get(class_name)
  BaseView.define_singleton_method(class_name, lambda { klass })
end
