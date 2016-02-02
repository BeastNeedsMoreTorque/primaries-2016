# rspec adds lib/ to the $LOAD_PATH, but we have a 'logger' in lib/ that
# masks Ruby's default 'logger'.
#
# https://github.com/rspec/rspec-core/issues/1983
$LOAD_PATH.delete_if { |p| File.expand_path(p) == File.expand_path('./lib') }

running_rspec_through_script_serve = (ENV['AP_API_KEY'] != nil)
ENV['AP_API_KEY'] = 'no-api-key-because-this-is-a-test-suite'

require_relative '../lib/env'
require_relative '../lib/paths'
Bundler.require(:development)

require_relative '../app/models/race'

RSpec.configure do |config|
  if running_rspec_through_script_serve
    config.filter_run_excluding(type: :feature)
  end
end

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

require_relative '../app/models/database'

def mock_database(collections, date_string, last_date_string, options={})
  date = Date.parse(date_string)
  last_date = Date.parse(last_date_string)

  collections[:parties] ||= [
    [ 'Dem', 'Democrats', 'Democratic', '1000', '500' ],
    [ 'GOP', 'Republicans', 'Republican', '2000', '1000' ]
  ]
  collections[:candidates] ||= [
    [ '1', 'Dem', 'Hillary Clinton', 'Clinton', 50, 10, 30.1, nil, DateTime.parse('2016-01-14T19:37:00.000Z'), nil ],
    [ '2', 'GOP', 'Marco Rubio', 'Rubio', 100, 20, 20.1, nil, DateTime.parse('2016-01-14T19:37:00.000Z'), nil ]
  ]
  collections[:races] ||= []

  copy = Database.production_copy(options[:override_copy] || {})

  races = collections[:races].map { |arr| Race.new(nil, *arr) }

  Database.stub_races_ap_isnt_reporting_yet(races)
  Database.mark_races_finished_from_copy(copy, races)

  collections[:races] = races.map { |race| race.to_a[1..-1] }

  Database.new(collections, date, last_date, copy)
end

def render_from_database(database)
  Dir["#{Paths.Dist}/**/*.html"].each { |f| File.unlink(f) }

  Dir[File.dirname(__FILE__) + '/../app/views/*.rb'].each do |path|
    next if path =~ /base_view.rb$/
    require File.absolute_path(path)
    basename = path.split('/').last.split('.').first
    class_name = basename.gsub(/(^|_)([^_]+)/) { $2.capitalize }
    klass = Object.const_get(class_name)
    klass.generate_all(database)
  end
end
