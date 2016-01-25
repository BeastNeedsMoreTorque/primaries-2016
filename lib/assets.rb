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
    javascripts/facebook.js
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

  def self.build(database)
    $logger.info("Building assets...")

    self.build_sprockets_assets
    self.build_digest_assets
    self.build_static_assets
  end

  # asset_path('main.css') -> '//asset_host/2016/stylesheets/main-abcdef.css'
  def self.asset_path(path)
    @asset_paths ||= {}
    @asset_paths[path] ||= begin
      dir = dir_for_path(path)

      path_without_digest = "#{Paths.Dist}/2016/#{dir}/#{path}"
      digest = asset_digest_hex(path_without_digest)

      arr = path.split(/\./, 2)

      "#{asset_host}/2016/#{dir}/#{arr[0]}-#{digest}.#{arr[1]}"
    end
  end

  # static_asset_path('pym.min.js') -> '//asset_host/2016/javascripts/pym.min.js'
  def self.static_asset_path(path)
    @static_asset_paths ||= {}
    @static_asset_paths[path] ||= begin
      dir = dir_for_path(path)
      "#{asset_host}/2016/#{dir}/#{path}"
    end
  end

  # image_path('clinton.png') -> '//asset_host/2016/images/clinton-abcdef.png'
  def self.image_path(name)
    @image_paths ||= {}
    @image_paths[name] ||= begin
      basename, extension = name.split(/\./)
      path_without_digest = "#{Paths.Assets}/images/#{name}"
      digest = asset_digest_hex(path_without_digest)
      "#{asset_host}/2016/images/#{basename}-#{digest}.#{extension}"
    end
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
    @asset_host = if ENV['ASSET_HOST']
      "//#{ENV['ASSET_HOST']}"
    else
      ''
    end
  end

  def self.asset_digest_hex(absolute_path)
    Digest::SHA1.file(absolute_path).hexdigest
  end

  def self.build_sprockets_assets
    @asset_paths = {}

    sprockets = Sprockets::Environment.new("#{Paths.Dist}/2016") do |env|
      env.cache = Sprockets::Cache::FileStore.new(Paths.Cache)
      env.digest_class = Digest::SHA1

      if ENV['DEBUG_ASSETS'] != 'true'
        env.js_compressor = :uglify
        env.css_compressor = :sass
      end

      env.logger = $logger
    end
    sprockets.append_path(Paths.Assets)

    SprocketsAssets.each do |filename|
      asset = sprockets.find_asset(filename)
      dirname, basename = filename.split('/')
      FileUtils.mkpath("#{Paths.Dist}/#{dirname}")
      $logger.debug("Writing asset #{asset.digest_path}")
      asset.write_to("#{Paths.Dist}/2016/#{asset.digest_path}")

      # Write the non-digest path as well. We'll use that in `asset_path()` to
      # determine the digest.
      asset.write_to("#{Paths.Dist}/2016/#{filename}")
    end
  end

  def self.build_digest_assets
    @image_paths = {}

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
