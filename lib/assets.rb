require 'json'

require_relative './logger'
require_relative './paths'

module Assets
  SprocketsAssets = %w(
    javascripts/stats.js
    javascripts/main.js
    stylesheets/main.css
    stylesheets/right-rail.css
    stylesheets/splash.css
  )

  StaticAssets = %w(
    images
    javascripts/pym.min.js
  )

  def self.clear
    %w(javascripts stylesheets images).each do |subdir|
      FileUtils.rm_rf("#{Paths.Dist}/2016/#{subdir}")
    end
  end

  def self.build(database)
    $logger.info("Building assets...")

    self.build_sprockets_assets
    self.build_static_assets
  end

  # asset_path('main.css') -> '/2016/stylesheets/main-abcdef.css'
  def self.asset_path(path)
    @asset_paths ||= {}
    @asset_paths[path] ||= begin
      path =~ /(.*)\.(css|js)$/

      raise "invalid path #{path}" if !$0
      dir = case $2
        when 'css' then 'stylesheets'
        when 'js' then 'javascripts'
        else raise "invalid asset extension #{$2}"
      end

      "/2016/#{dir}/#{$1}-#{asset_digest_hex("#{dir}/#{path}")}.#{$2}"
    end
  end

  def self.asset_digest_hex(filename)
    path = "#{Paths.Dist}/2016/#{filename}"
    Digest::SHA1.file(path).hexdigest
  end

  private

  def self.build_sprockets_assets
    sprockets = Sprockets::Environment.new("#{Paths.Dist}/2016") do |env|
      env.cache = Sprockets::Cache::FileStore.new(Paths.Cache)
      env.digest_class = Digest::SHA1
      env.js_compressor = :uglify
      env.css_compressor = :sass
      env.logger = $logger
    end
    sprockets.append_path(Paths.Assets)

    SprocketsAssets.each do |filename|
      asset = sprockets.find_asset(filename)
      dirname, basename = filename.split('/')
      FileUtils.mkpath("#{Paths.Dist}/#{dirname}")
      $logger.debug("Writing asset #{asset.digest_path}")
      asset.write_to("#{Paths.Dist}/2016/#{filename}")
      asset.write_to("#{Paths.Dist}/2016/#{asset.digest_path}")
    end
  end

  def self.build_static_assets
    StaticAssets.each do |filename|
      $logger.debug("Copying asset #{filename}")
      FileUtils.cp_r("#{Paths.Assets}/#{filename}", "#{Paths.Dist}/2016/#{filename}")
    end
  end
end
