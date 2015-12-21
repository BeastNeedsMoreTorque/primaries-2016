require 'json'
require 'net/http'
require 'uri'

require_relative './logger'
require_relative './models'

module AP
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

  def self.GET_json(uri_string)
    $logger.info("GET #{uri_string}")
    uri = URI(uri_string)
    response = Net::HTTP.get_response(uri)
    raise "HTTP #{response.code} #{response.message} from server. Body: #{response.body}" if response.code != '200'
    JSON.parse(response.body, create_additions: false, symbolize_names: true)
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
