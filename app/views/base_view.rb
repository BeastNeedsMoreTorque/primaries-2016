require_relative '../../lib/paths'

class BaseView
  def render(options)
    if options[:partial]
      template = File.read(File.expand_path("../../templates/_#{options[:partial]}.html.haml", __FILE__))
      haml_engine = Haml::Engine.new(template)
      haml_engine.render(self)
    end
  end

  def asset_path(path); Assets.asset_path(path); end
  def race_months; RaceDay.all.group_by{ |rd| rd.date.to_s[0...7] }.values; end
  def party; Party.all; end

  def template
    @template ||= File.read(File.expand_path("../../templates/#{template_name}.html.haml", __FILE__))
  end

  protected

  def self.generate_for_view(view)
    path = "#{Paths.Dist}/#{view.output_path}"
    $logger.debug("Generating #{path}")
    output = render_view_haml(view)
    self.write_contents(path, output)
  end

  def self.render_view_haml(view)
    haml_engine = Haml::Engine.new(view.template)
    haml_engine.render(view)
  end

  def self.write_contents(path, contents)
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, 'w') { |f| f.write(contents) }
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
