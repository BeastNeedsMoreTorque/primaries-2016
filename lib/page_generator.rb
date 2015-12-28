require_relative './logger'

module PageGenerator
  def write_string_to_path(string, path)
    $logger.debug("Writing #{path}")
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, 'w') { |f| f.write(string) }
  end
end
