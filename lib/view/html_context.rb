require_relative '../paths'

class HtmlContext
  def render(options)
    if options[:partial]
      template = File.read(File.expand_path("../../../templates/_#{options[:partial]}.html.haml", __FILE__))
      haml_engine = Haml::Engine.new(template)
      haml_engine.render(self)
    end
  end
end

Dir[File.dirname(__FILE__) + '/../../app/models/*.rb'].each do |path|
  next if path =~ /database.rb$/
  require path
  basename = path.split('/').last.split('.').first
  class_name = basename.gsub(/(^|_)([^_]+)/) { $2.capitalize }
  klass = Object.const_get(class_name)
  HtmlContext.define_singleton_method(class_name, lambda { klass })
end
