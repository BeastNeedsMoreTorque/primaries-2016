require_relative './logger'
require_relative './paths'

module Assets
  extend Sprockets::DigestUtils

  def self.clear
    $logger.info("Clearing assets...")

    %w(javascripts stylesheets topojson).each do |subdir|
      FileUtils.rm_rf("#{Paths.Dist}/#{subdir}")
    end
  end

  def self.build
    $logger.info("Rebuilding assets...")

    # Create main.js and main.css
    sprockets = Sprockets::Environment.new("#{Paths.Dist}/2016") do |env|
      env.logger = $logger
    end
    sprockets.append_path(Paths.Assets)
    %w(javascripts/main.js stylesheets/main.css).each do |filename|
      asset = sprockets.find_asset(filename)
      dirname, basename = filename.split('/')
      FileUtils.mkpath("#{Paths.Dist}/#{dirname}")
      $logger.debug("Writing asset #{asset.digest_path}")
      asset.write_to("#{Paths.Dist}/2016/#{filename}")
      asset.write_to("#{Paths.Dist}/2016/#{asset.digest_path}")
    end

    # Copy static assets
    %w(topojson).each do |filename|
      $logger.debug("Copying asset #{filename}")
      FileUtils.cp_r("#{Paths.Assets}/#{filename}", "#{Paths.Dist}/2016")
    end
  end

  def self.main_css_path
    @main_css_path ||= "/2016/stylesheets/main-#{asset_digest_hex('stylesheets/main.css')}.css"
  end

  def self.main_js_path
    @main_js_path ||= "/2016/javascripts/main-#{asset_digest_hex('javascripts/main.js')}.js"
  end

  private

  def self.asset_digest_hex(filename)
    digest = digest_class.new
    File.open("#{Paths.Dist}/2016/#{filename}", 'r') { |f| digest << f.read }
    pack_hexdigest(digest.digest)
  end
end
