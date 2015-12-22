require 'fileutils'
require 'json'
require 'net/http'
require 'uri'

require_relative './logger'
require_relative './models'
require_relative './paths'

# Requests data from the AP Elections API and stores it in `cache/ap`. Then
# returns it as JSON when requested.
module AP
  def self.update_cache
    self.GET_del_super
    self.GET_all_primary_election_days
  end

  # Requests election results for the given date.
  #
  # Returns an ElectionDay or raises an error.
  def self.GET_primaries_election_day(date)
    uri = "https://api.ap.org/v2/elections/#{date.to_s}?apikey=#{api_key}&level=fipscode&national=true&officeID=P&format=json#{is_test_query_param}"
    obj = GET_json(uri)
    ElectionDay.new(obj)
  end

  # Requests all 2016 primary results.
  #
  # Returns an Array of ElectionDay objects.
  def self.GET_all_primary_election_days
    obj = GET_json("https://api.ap.org/v2/elections?format=json&apikey=#{api_key}")
    obj[:elections]
      .select { |e| !!e[:testResults] == is_test }
      .map { |e| e[:electionDate] }
      .select { |d| d > '2016-00-00' && d < '2016-07-00' } # http://customersupport.ap.org/doc/eln/2016_Election_Calendar.pdf
      .map { |d| GET_primaries_election_day(d) }
  end

  # Requests delegate counts.
  #
  # Returns a DelSuper or raises an error.
  #
  # This performs two requests: first to /reports, and second to
  # /reports/id-returned-by-first-request.
  def self.GET_del_super
    uri1 = "https://api.ap.org/v2/reports?type=Delegates&subtype=delsuper&format=json&apikey=#{api_key}#{is_test_query_param}"
    obj1 = GET_json(uri1)
    report_id = obj1[:reports][0][:id]
    uri2 = "#{report_id}?format=json&apikey=#{api_key}" # no "test" parameter
    obj2 = GET_json(uri2)
    DelSuper.new(obj2[:delSuper])
  end

  private

  # Loads JSON: from `cache/ap` if it's there, from the server otherwise.
  #
  # If it loads from the server, it saves the result in the cache.
  def self.GET_json(uri_string)
    path = uri_to_path(uri_string)
    if File.exist?(path)
      load_json_from_cache(uri_string)
    else
      GET_json_and_save(uri_string)
    end
  end

  # Sends a GET request, saves the result to `cache/ap`, and returns the saved
  # JSON.
  def self.GET_json_and_save(uri_string)
    $logger.info("GET #{uri_string}")
    uri = URI(uri_string)
    response = Net::HTTP.get_response(uri)
    raise "HTTP #{response.code} #{response.message} from server. Body: #{response.body}" if response.code != '200'
    save_string_to_cache(response.body, uri_string)
    load_json_from_cache(uri_string)
  end

  # Reads a GET response from `cache/ap`, or raises an error if there is no
  # cached value.
  def self.load_json_from_cache(uri_string)
    path = uri_to_path(uri_string)
    $logger.debug("load #{path}")
    File.open(path, 'r') { |f| JSON.load(f, nil, create_additions: false, max_nesting: false, symbolize_names: true) }
  end

  # Saves a GET response to `cache/ap`.
  def self.save_string_to_cache(string, uri_string)
    path = uri_to_path(uri_string)
    FileUtils.mkdir_p(File.dirname(path))
    $logger.debug("save #{path}")
    File.open(path, 'w') { |f| f.write(string) }
  end

  def self.uri_to_path(uri_string)
    "#{Paths.Cache}/ap/" + uri_string.sub('https://api.ap.org/v2/', '').gsub('/', '__')
  end

  def self.api_key
    raise 'You must set the AP_API_KEY environment variable' if !ENV['AP_API_KEY']
    ENV['AP_API_KEY']
  end

  def self.is_test
    !!ENV['AP_TEST']
  end

  def self.is_test_query_param
    is_test ? '&test=true' : ''
  end
end
