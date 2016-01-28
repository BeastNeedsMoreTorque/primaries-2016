require 'tilt'

require_relative '../../lib/assets'
require_relative '../../lib/paths'

class BaseView
  attr_reader(:database)
  StateRaceDaysColumn = Struct.new(:html_class, :label)
  Months = %w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec) # http://www.apstylebook.com/online/?do=entry&id=1939&src=AE

  def initialize(database)
    @database = database
  end

  def today; database.today; end
  def last_date; database.last_date; end
  def copy; database.copy; end

  def layout; nil; end

  # Turns Markdown into HTML
  def render_markdown(markdown_string)
    @@markdown ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML.new())
    @@markdown.render(markdown_string)
  end

  # e.g., for AllPrimariesView, "all-primaries"
  def body_class
    self.class.name.gsub(/([A-Z])/){ "-#{$1.downcase}" }[1..-6]
  end

  # 1234567 -> "1,234,567"
  def format_int(int)
    int.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")
  end

  # a DateTime -> "2016-01-19T20:54:12.345Z"
  #
  # (We need to format times in JavaScript, because only JavaScript knows the
  # user's time zone.)
  def format_datetime(datetime)
    datetime.new_offset(0).iso8601.sub('+00:00', '.000Z')
  end

  # nil -> "N/A"; 32.4 -> "32.4%"
  def format_percent_or_nil(percent_or_nil)
    if percent_or_nil.nil?
      'N/A'
    else
      "#{percent_or_nil}%"
    end
  end

  # 2016-01-19 -> "Jan 19"
  def format_date(date)
    "#{Months[date.month - 1]} #{date.day}"
  end

  def render_state_race_days_by_date
    render(partial: 'state-race-days-table', locals: {
      columns: [
        [ 'date', 'Date' ],
        [ 'state', 'State' ],
        [ 'party', 'Party' ],
        [ 'n-delegates', 'Delegates' ]
      ].map { |arr| StateRaceDaysColumn.new(*arr) },
      hide_repeats_column: 'date',
      races: races
    })
  end

  def render_state_race_days_by_state
    render(partial: 'state-race-days-table', locals: {
      columns: [
        [ 'state', 'State' ],
        [ 'date', 'Date' ],
        [ 'party', 'Party' ],
        [ 'n-delegates', 'Delegates' ]
      ].map { |arr| StateRaceDaysColumn.new(*arr) },
      hide_repeats_column: 'state',
      races: races.sorted_by_state_name_and_race_day
    })
  end

  Database::CollectionNames.each do |collection_name|
    define_method(collection_name.to_sym) { database.send(collection_name) }
  end

  def render(options)
    locals = options[:locals] || {}
    if options[:partial]
      parts = options[:partial].split('/')
      parts[-1] = "_#{parts[-1]}"
      template = BaseView.load_template(parts.join('/'))
      template.render(self, locals)
    elsif options[:layout]
      raise "You tried to render a layout without a block" if !block_given?
      text = yield
      template = BaseView.load_template("layouts/#{options[:layout]}")
      template.render(self, { main_content: text }.merge(locals))
    end
  end

  def asset_path(path); Assets.asset_path(path); end
  def image_path(path); Assets.image_path(path); end
  def race_months; database.race_days.group_by{ |rd| rd.date.to_s[0...7] }.values; end

  # Tries to return an absolute path to the image -- that is, with the protocol.
  #
  # Falls back to image_path(path).
  #
  # Logic:
  #
  # * If ASSET_HOST is set, return an absolute path, with protocol `http`
  # * Otherwise, return image_path(path)
  def absolute_image_path_if_possible(path)
    url = image_path(path)
    if url[0, 2] == '//'
      "http:#{url}"
    else
      url
    end
  end

  # Returns inline <svg> data from the given `path`
  def map_svg(path)
    return '' if %w(states/DA).include?(path)

    # a .svg file includes a DOCTYPE, but we're including it inline so we don't
    # want it.
    header_length = 137
    @map_svg ||= {}
    @map_svg[path] ||= File.read("#{Paths.Assets}/maps/#{path}.svg")[header_length .. -1]
  end

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
