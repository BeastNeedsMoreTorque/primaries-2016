require 'haml'

require_relative './logger'

module PageGenerator
  protected

  def generate_html(template, view)
    haml_engine = Haml::Engine.new(template)
    output = haml_engine.render(view)
    path = "#{Paths.Dist}/#{view.html_path}"
    write_string_to_path(output, path)
  end

  private

  def write_string_to_path(string, path)
    $logger.debug("Writing #{path}")
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, 'w') { |f| f.write(string) }
  end
end
