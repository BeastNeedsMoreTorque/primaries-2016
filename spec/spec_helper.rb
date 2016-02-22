# rspec adds lib/ to the $LOAD_PATH, but we have a 'logger' in lib/ that
# masks Ruby's default 'logger'.
#
# https://github.com/rspec/rspec-core/issues/1983
$LOAD_PATH.delete_if { |p| File.expand_path(p) == File.expand_path('./lib') }

require 'fileutils'

require_relative '../lib/env'
Bundler.require(:development)

ENV['DIST_PATH'] = './tmp/dist'
require_relative '../lib/paths'

class AvoidRackStatic304Responses
  def initialize(app)
    @app = app
  end

  def call(env)
    env['HTTP_IF_MODIFIED_SINCE'] = nil
    @app.call(env)
  end
end

require 'capybara/rspec'
Capybara.configure do |config|
  config.default_driver = :webkit

  config.app = Rack::Builder.new(quiet: true) do
    dir = Paths.Dist

    # capybara-webkit *requires* 200 responses. 304s leave page.html empty and
    # tests fail.
    no_cache = { 'Cache-Control' => 'no-cache' }
    use(AvoidRackStatic304Responses) # https://github.com/thoughtbot/capybara-webkit/issues/724
    use(Rack::Static, urls: { '/2016' => '2016.html' }, root: dir, header_rules: [[ :all, no_cache ]])
    use(Rack::TryStatic, root: dir, urls: [ '/2016/primaries' ], try: [ '.html' ], header_rules: [[ :all, no_cache ]])
    use(Rack::Static, urls: [ '/2016' ], root: dir, header_rules: [[ :all, no_cache ]])

    run lambda { |env|
      $stderr.puts "Failed request: #{env}"
      [ 404, { 'Content-Type' => 'text/html; charset=utf-8' }, [ 'Not Found' ]]
    }
  end
end
Capybara::Webkit.configure do |config|
  config.block_unknown_urls = true # nix stats/ads
  config.skip_image_loading = true # speedup
end

require_relative '../lib/assets'

Assets.build # so asset_path() works

require_relative '../app/models/database'

def mock_database(date_string, last_date_string, source_overrides={})
  now = Time.parse(date_string)
  last_date = Date.parse(last_date_string)

  sheets_source = source_overrides[:sheets_source] || Database.default_sheets_source

  Database.new(
    source_overrides[:copy_source] || Database.default_copy_source,
    sheets_source,
    source_overrides[:geo_ids_source] || Database.default_geo_ids_source,
    source_overrides[:ap_del_super_source] || Database.default_ap_del_super_source,
    source_overrides[:ap_election_days_source] || Database.default_ap_election_days_source,
    source_overrides[:pollster_source] || Database.default_pollster_source(sheets_source.parties, sheets_source.races),
    now,
    last_date,
    source_overrides[:focus_race_day_id] || Database.FocusRaceDayId
  )
end

RSpec.configure do |config|
  config.before(:each) do
    FileUtils.rm(Dir["#{Paths.Dist}/**/*.html"] + Dir["#{Paths.Dist}/**/*.json"])
  end
end
