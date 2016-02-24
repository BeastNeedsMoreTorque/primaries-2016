require 'json'

require_relative './logger'
require_relative './paths'

module Assets
  # JavaScript assets we concatenate and minify.
  #
  # To refer to `main.js` from a template, write `asset_path('main.js')`.
  JavascriptAssets = {
    'ga.js' => %w(ga.js),
    'stats.js' => %w(stats.js),
    'main.js' => %w(
      vendor/jquery-2.2.0.js
      wait_for_font_then.js
      render_time.js
      format_int.js
      format_percent.js
      ellipsize_table.js
      polyfill_array_fill.js
      position_svg_cities.js
      countdown.js
      state-race-days.js
      dot-groups.js
      race-day.js
      delegate-summary.js
      all-primaries.js
      social.js
    ),
    'splash.js' => %w(
      vendor/jquery-2.2.0.js
      countdown.js
      format_int.js
      format_percent.js
      position_svg_cities.js
      splash.js
    ),
    'primary-right-rail.js' => %w(
      vendor/jquery-2.2.0.js
      format_int.js
      format_percent.js
      primary-right-rail.js
    )
  }

  # SCSS assets we compile with SassC.
  #
  # To refer to `main.css` from a template, write `asset_path('main.css')`.
  StylesheetAssets = %w(
    main.css
    mobile-ad.css
    primaries-linkout-image.css
    primaries-right-rail.css
    splash.css
  )

  # Assets we serve with a sha1 digest.
  #
  # The sha1 digest lets us change a file in the future. For instance, we may
  # color-correct an image. If we don't put such an image in DigestAssets, then
  # proxy servers and clients will serve the old version instead of the new one.
  #
  # To refer to `images/clinton.png` from a template, write
  # `image_path('clinton.png')`.
  DigestAssets = %w(
    images/**/*.{png,jpg,gif,svg}
  )

  # Assets that never change.
  #
  # pym.min.js never changes, because we hard-code links to it from our CMS.
  #
  # To refer to `javascripts/pym.min.js` from a template, write it explicitly.
  StaticAssets = %w(
    javascripts/pym.min.js
    stylesheets/proxima-nova-condensed.css
  )

  def self.build
    $logger.info("Building assets...")

    @asset_paths = {}
    self.build_javascript_assets
    self.build_stylesheet_assets
    self.build_digest_assets
    self.build_static_assets
  end

  # asset_path('main.css') -> '//asset_host/2016/stylesheets/main-abcdef.css'
  def self.asset_path(path)
    if !@asset_paths.include?(path)
      raise "You requested asset_path('#{path}'), but Assets did not compile #{path}."
    end

    "#{asset_host}/2016/#{@asset_paths[path]}"
  end

  # static_asset_path('pym.min.js') -> '//asset_host/2016/javascripts/pym.min.js'
  def self.static_asset_path(path)
    dir = dir_for_path(path)
    "#{asset_host}/2016/#{dir}/#{path}"
  end

  # image_path('clinton.png') -> '//asset_host/2016/images/clinton-abcdef.png'
  def self.image_path(name)
    digest_asset_path('images/' + name)
  end

  # digest_asset_path('images/clinton.png') -> '//asset_host/2016/images/clinton-abcdef.png'
  def self.digest_asset_path(path)
    if !@digest_asset_paths.include?(path)
      raise "You requested image_path('#{name}'), but Assets did not compile #{name}."
    end
    "#{asset_host}/2016/#{@digest_asset_paths[path]}"
  end

  private

  # dir_for_path('foo.css') -> 'stylesheets'
  # dir_for_path('foo.js') -> 'javascripts'
  # dir_for_path('blah.txt') -> RuntimeError
  def self.dir_for_path(path)
    path =~ /(.*)\.(css|js)$/

    raise "invalid path #{path}" if !$0
    case $2
      when 'css' then 'stylesheets'
      when 'js' then 'javascripts'
      else raise "invalid asset extension #{$2}"
    end
  end

  def self.asset_host
    @asset_host = if ENV['ASSET_HOST'] && !ENV['ASSET_HOST'].empty?
      "//#{ENV['ASSET_HOST']}"
    else
      ''
    end
  end

  def self.string_digest_hex(string)
    Digest::SHA1.hexdigest(string)
  end

  def self.build_stylesheet_assets
    FileUtils.mkpath("#{Paths.Dist}/2016/stylesheets")

    for filename in StylesheetAssets
      scss_filename = "#{filename}.scss"
      scss = IO.read("#{Paths.Assets}/stylesheets/#{scss_filename}")

      engine = SassC::Engine.new(scss, {
        style: :compact,
        syntax: :scss,
        filename: filename,
        cache: false,
        load_paths: [ "#{Paths.Assets}/stylesheets" ],
        sourcemap: :none
      })
      css = engine.render

      write_asset_with_digest('stylesheets', filename, css)
    end
  end

  def self.build_javascript_assets
    FileUtils.mkpath("#{Paths.Cache}/uglified-javascript")
    FileUtils.mkpath("#{Paths.Dist}/2016/javascripts")

    path_to_contents = JavascriptAssets.values.flatten.each_with_object({}) do |path, h|
      h[path] = read_javascript_source(path)
    end

    JavascriptAssets.each do |output_filename, input_filenames|
      js = input_filenames.map{ |p| path_to_contents[p] }.join("\n")
      write_asset_with_digest('javascripts', output_filename, js)
    end
  end

  def self.read_javascript_source(path)
    raw_js = IO.read("#{Paths.Assets}/javascripts/#{path}")

    if ENV['DEBUG_ASSETS'] == 'true'
      raw_js
    else
      digest = string_digest_hex(raw_js)
      cache_path = "#{Paths.Cache}/uglified-javascript/#{digest}"
      begin
        IO.read(cache_path)
      rescue Errno::ENOENT
        require 'uglifier'
        require 'therubyracer'
        js = Uglifier.compile(raw_js)
        IO.write(cache_path, js)
        js
      end
    end
  end

  def self.build_digest_assets
    @digest_asset_paths = {}

    DigestAssets.each do |pattern|
      Dir["#{Paths.Assets}/#{pattern}"].each do |absolute_filename|
        digest = Digest::SHA1.file(absolute_filename).hexdigest
        filename = absolute_filename[(Paths.Assets.length + 1) .. -1]
        relative_path, extension = filename.split(/\./)
        output_relative_filename = "#{relative_path}-#{digest}.#{extension}"
        output_filename = "#{Paths.Dist}/2016/#{output_relative_filename}"
        $logger.debug("Copying asset #{output_relative_filename}")
        FileUtils.mkpath(File.dirname(output_filename))
        FileUtils.cp(absolute_filename, output_filename)

        @digest_asset_paths[filename] = output_relative_filename
      end
    end
  end

  def self.write_asset_with_digest(dirname, filename, contents)
    digest = Assets.string_digest_hex(contents)

    pre_ext, ext = filename.split(/\./)

    digest_filename = "#{pre_ext}-#{digest}.#{ext}"

    $logger.debug("Writing asset #{dirname}/#{digest_filename}")

    IO.write("#{Paths.Dist}/2016/#{dirname}/#{digest_filename}", contents)

    @asset_paths[filename] = "#{dirname}/#{digest_filename}"
  end

  def self.build_static_assets
    StaticAssets.each do |filename|
      $logger.debug("Copying asset #{filename}")
      FileUtils.cp_r("#{Paths.Assets}/#{filename}", "#{Paths.Dist}/2016/#{filename}")
    end
  end
end
