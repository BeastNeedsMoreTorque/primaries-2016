require 'json'

require_relative './logger'
require_relative './paths'

module Assets
  # Assets we compile with Sprockets.
  #
  # Sprockets is useful when there's code like `//= require 'subfile.js'`.
  #
  # To refer to `javascripts/main.js` from a template, write
  # `asset_path('main.js')`.
  SprocketsAssets = %w(
    javascripts/ga.js
    javascripts/stats.js
    javascripts/main.js
    javascripts/splash.js
    javascripts/primary-right-rail.js
    stylesheets/main.css
    stylesheets/splash.css
    stylesheets/primaries-right-rail.css
    stylesheets/mobile-ad.css
  )

  # Assets we serve with a sha1 digest.
  #
  # The sha1 digest lets us change a file in the future. For instance, we may
  # color-correct an image. If we don't put such an image in DigestAssets, then
  # proxy servers and clients will serve the old version instead of the new one.
  #
  # To refer to `images/clinton.png` from a template, write
  # `image_path('clinton')`.
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

    self.build_sprockets_assets
    self.build_digest_assets
    self.build_static_assets
  end

  # asset_path('main.css') -> '//asset_host/2016/stylesheets/main-abcdef.css'
  def self.asset_path(path)
    if !@sprockets_asset_paths.include?(path)
      raise "You requested asset_path('#{path}'), but Assets did not compile #{path}."
    end

    "#{asset_host}/2016/#{@sprockets_asset_paths[path]}"
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

  def self.build_sprockets_assets
    @sprockets_asset_paths = {}

    self.build_css_assets(SprocketsAssets.select { |a| a =~ /\.css$/ })
    self.build_js_assets(SprocketsAssets.select { |a| a =~ /\.js$/ })
  end

  def self.build_css_assets(output_paths)
    FileUtils.mkpath("#{Paths.Dist}/2016/stylesheets")

    output_paths.each do |filename|
      scss = IO.read("#{Paths.Assets}/#{filename}.scss")

      engine = SassC::Engine.new(scss, {
        style: :compact,
        syntax: :scss,
        filename: filename,
        cache: false,
        load_paths: [ "#{Paths.Assets}/stylesheets" ],
        sourcemap: :none
      })
      css = engine.render
      digest = Assets.string_digest_hex(css)

      dirname, basename = filename.split(/\//)
      pre_ext, ext = filename.split(/\./)

      digest_filename = "#{pre_ext}-#{digest}.#{ext}"

      $logger.debug("Writing asset #{digest_filename}")

      IO.write("#{Paths.Dist}/2016/#{digest_filename}", css)

      @sprockets_asset_paths[basename] = digest_filename
    end
  end

  def self.build_js_assets(output_paths)
    FileUtils.mkpath("#{Paths.Dist}/2016/javascripts")

    sprockets = Sprockets::Environment.new("#{Paths.Dist}/2016") do |env|
      env.cache = Sprockets::Cache::FileStore.new(Paths.Cache)
      env.digest_class = Digest::SHA1

      if ENV['DEBUG_ASSETS'] != 'true'
        env.js_compressor = :uglify
      end

      env.logger = $logger
    end
    sprockets.append_path(Paths.Assets)

    output_paths.each do |filename|
      asset = sprockets.find_asset(filename)
      source = asset.source
      digest = Assets.string_digest_hex(source)

      dirname, basename = filename.split(/\//)
      pre_ext, ext = filename.split(/\./)

      digest_filename = "#{pre_ext}-#{digest}.#{ext}"

      $logger.debug("Writing asset #{digest_filename}")

      IO.write("#{Paths.Dist}/2016/#{digest_filename}", source)

      @sprockets_asset_paths[basename] = digest_filename
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

  def self.build_static_assets
    StaticAssets.each do |filename|
      $logger.debug("Copying asset #{filename}")
      FileUtils.cp_r("#{Paths.Assets}/#{filename}", "#{Paths.Dist}/2016/#{filename}")
    end
  end
end
