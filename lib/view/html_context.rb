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
