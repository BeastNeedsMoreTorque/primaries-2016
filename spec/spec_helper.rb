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

RSpec.configure do |config|
  if running_rspec_through_script_serve
    config.filter_run_excluding(type: :feature)
  end
end

require 'capybara/rspec'
Capybara.configure do |config|
  config.default_driver = :webkit
  config.app_host = 'http://localhost:3000'
  config.run_server = false
end
Capybara::Webkit.configure do |config|
  config.block_unknown_urls = true
end

require_relative '../app/models/database'

def mock_database(collections, date_string, last_date_string)
  date = Date.parse(date_string)
  last_date = Date.parse(last_date_string)

  collections[:parties] ||= [
    [ 'Dem', 'Democrats', 'Democratic', '1000', '500' ],
    [ 'GOP', 'Republicans', 'Republican', '2000', '1000' ]
  ]
  collections[:candidates] ||= [
    [ '1', 'Dem', 'Hillary Clinton', 'Clinton', 50, 10, 30.1, DateTime.parse('2016-01-14T19:37:00.000Z') ],
    [ '2', 'GOP', 'Marco Rubio', 'Rubio', 100, 20, 20.1, DateTime.parse('2016-01-14T19:37:00.000Z') ]
  ]
  collections[:races] ||= []
  Database.stub_races_ap_isnt_reporting_yet(collections[:races])

  Database.new(collections, date, last_date, Database.production_copy)
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
