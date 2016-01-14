require 'tilt'

require_relative '../../lib/assets'
require_relative '../../lib/paths'

class BaseView
  attr_reader(:database)

  def initialize(database)
    @database = database
  end

  def today; database.today; end
  def copy; database.copy; end

  def page_title; '2016 Election Coverage'; end

  def layout; nil; end
  def layout_stylesheets; []; end

  # e.g., for AllPrimariesView, "all-primaries"
  def body_class
    self.class.name.gsub(/([A-Z])/){ "_#{$1.downcase}" }[1..-6]
  end

  def meta
    @meta ||= {
      page_description: 'Huffington Post coverage of the 2016 Presidential Primaries and Election',
    }
  end

  Database::CollectionNames.each do |collection_name|
    define_method(collection_name.to_sym) { database.send(collection_name) }
  end

  def render(options, locals={})
    if options[:partial]
      template = BaseView.load_template("_#{options[:partial]}")
      template.render(self, locals)
    elsif options[:layout]
      raise "You tried to render a layout without a block" if !block_given?
      text = yield
      template = BaseView.load_template("layouts/#{options[:layout]}")
      template.render(self, { main_content: text }.merge(locals))
    end
  end

  def asset_path(path); Assets.asset_path(path); end
  def race_months; database.race_days.group_by{ |rd| rd.date.to_s[0...7] }.values; end

  def template_name
    t = self.class.name.gsub(/([A-Z])/) { "-#{$1.downcase}" }
    t[1..-6]
  end

  protected

  class CachingTemplate < ::Temple::Templates::Tilt
    def prepare
      template_filename = eval_file
      cached_result_filename = "#{Paths.Cache}/templates/#{template_filename[Paths.Templates.length + 1 .. -1]}"

      template_sha1 = digest_file_at_path(template_filename)
      cache_contents = begin
        IO.read(cached_result_filename, encoding: 'utf-8')
      rescue Errno::ENOENT
        ''
      end

      cache_sha1, cache_src = cache_contents.split(/\n/, 2)

      if cache_sha1 == template_sha1
        @src = cache_src
      else
        @src = super
        FileUtils.mkdir_p(File.dirname(cached_result_filename))
        IO.write(cached_result_filename, "#{template_sha1}\n#{@src}", encoding: 'utf-8')
        @src
      end
    end

    private

    def digest_file_at_path(path)
      Digest::SHA1.file(path).hexdigest
    end
  end

  HamlitTemplate = CachingTemplate.create(Hamlit::Engine, register_as: :haml)
  Tilt.register(HamlitTemplate, 'haml')

  def self.template_name_to_template(template_name)
    @template_name_to_template ||= {}
    @template_name_to_template[template_name] ||= load_template(template_name)
  end

  def self.load_template(template_name)
    @templates ||= {}
    @templates[template_name] ||= begin
      filename = File.expand_path("../../templates/#{template_name}.html.haml", __FILE__)
      Tilt.new(filename)
    end
  end

  def self.generate_for_view(view)
    path = "#{Paths.Dist}/#{view.output_path}"
    $logger.debug("Generating #{path}")
    output = render_view(view)
    if view.layout
      template = load_template("layouts/#{view.layout}")
      output = template.render(view, { main: output })
    end
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
