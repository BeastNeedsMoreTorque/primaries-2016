require_relative './paths'

module Assets
  extend Sprockets::DigestUtils

  def self.main_css_path
    @main_css_path ||= "/stylesheets/main-#{asset_digest_hex('stylesheets/main.css')}.css"
  end

  def self.main_js_path
    @main_js_path ||= "/javascripts/main-#{asset_digest_hex('javascripts/main.js')}.js"
  end

  private

  def self.asset_digest_hex(filename)
    digest = digest_class.new
    File.open("#{Paths.Dist}/#{filename}", 'r') { |f| digest << f.read }
    pack_hexdigest(digest.digest)
  end
end
