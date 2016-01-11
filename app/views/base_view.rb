require 'tilt'

require_relative '../../lib/paths'

class BaseView
  attr_reader(:database)

  def initialize(database)
    @database = database
  end

  def today; database.today; end

  Database::CollectionNames.each do |collection_name|
    define_method(collection_name.to_sym) { database.send(collection_name) }
  end

  def render(options)
    if options[:partial]
      filename = File.expand_path("../../templates/_#{options[:partial]}.html.haml", __FILE__)
      template = Tilt.new(filename)
      template.render(self)
    end
  end

  def asset_path(path); Assets.asset_path(path); end
  def race_months; database.race_days.group_by{ |rd| rd.date.to_s[0...7] }.values; end

  def template_name
    t = self.class.name.gsub(/([A-Z])/) { "-#{$1.downcase}" }
    t[1..-6]
  end

  protected

  def self.template_name_to_template(template_name)
    @template_name_to_template ||= {}
    @template_name_to_template[template_name] ||= load_template(template_name)
  end

  def self.load_template(template_name)
    filename = File.expand_path("../../templates/#{template_name}.html.haml", __FILE__)
    Tilt.new(filename)
  end

  def self.generate_for_view(view)
    path = "#{Paths.Dist}/#{view.output_path}"
    $logger.debug("Generating #{path}")
    output = render_view(view)
    self.write_contents(path, output)
  end

  def self.render_view(view)
    template = template_name_to_template(view.template_name)
    template.render(view)
  end

  def self.write_contents(path, contents)
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, 'w') { |f| f.write(contents) }
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
