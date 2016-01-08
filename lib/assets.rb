require 'json'

require_relative './logger'
require_relative './paths'

module Assets
  extend Sprockets::DigestUtils

  SprocketsAssets = %w(
    javascripts/main.js
    stylesheets/main.css
    stylesheets/right-rail.css
  )

  StaticAssets = %w(
    topojson
    images
  )

  def self.clear
    %w(javascripts stylesheets topojson).each do |subdir|
      FileUtils.rm_rf("#{Paths.Dist}/2016/#{subdir}")
    end
  end

  def self.build
    $logger.info("Building assets...")

    self.build_dynamic_js
    self.build_sprockets_assets
    self.build_static_assets
  end
  # asset_path('main.css') -> '/2016/stylesheets/main-abcdef.css'
  def self.asset_path(path)
    path =~ /(.*)\.(css|js)$/

    raise "invalid path #{path}" if !$0
    dir = case $2
      when 'css' then 'stylesheets'
      when 'js' then 'javascripts'
      else raise "invalid asset extension #{$2}"
    end

    "/2016/#{dir}/#{$1}-#{asset_digest_hex("#{dir}/#{path}")}.#{$2}"
  end

  def self.digest_file_at_path(path)
    digest = digest_class.new
    File.open(path, 'r') { |f| digest << f.read }
    pack_hexdigest(digest.digest)
  end

  private

  def self.build_dynamic_js
    require_relative '../app/models/state'
    $logger.debug('Writing javascripts/state.js')
    File.open("#{Paths.Assets}/javascripts/states.js", 'w') do |f|
      f.write <<-EOT.gsub(/^\s{8}/, '')
        // Automatically generated from states.rb. See lib/assets.rb.
        var States = #{JSON.dump(State.all)};
        var StatesByCode = {};
        var StatesByFipsInt = {};
        States.forEach(function(state) {
          StatesByCode[state.code] = state;
          StatesByFipsInt[state.fipsInt] = state;
        });
        EOT
    end
  end

  def self.build_sprockets_assets
    sprockets = Sprockets::Environment.new("#{Paths.Dist}/2016") do |env|
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
      FileUtils.cp_r("#{Paths.Assets}/#{filename}", "#{Paths.Dist}/2016")
    end
  end

  def self.asset_digest_hex(filename)
    digest_file_at_path("#{Paths.Dist}/2016/#{filename}")
  end
end
