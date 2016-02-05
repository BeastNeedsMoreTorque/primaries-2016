require 'oj'
require 'net/http'
require 'uri'

require_relative './logger'

class HttpClient
  class HttpInterface
    def get(url, maybe_etag)
      uri = URI(url)

      $logger.info("GET #{uri}")

      req = Net::HTTP::Get.new(uri)
      req['If-None-Match'] = maybe_etag if maybe_etag

      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(req)
      end
    end
  end

  attr_reader(:ap_api_key, :is_test, :is_zero)

  def initialize(http_interface, ap_api_key, is_test, is_zero)
    @http_interface = http_interface
    @ap_api_key = ap_api_key
    @is_test = is_test
    @is_zero = is_zero
  end

  # Fetches a String document from the server and its String etag.
  #
  # Raises an error if the server does not respond.
  # Raises an error if the response code is not 200.
  # Raises an error if the response is not valid JSON.
  #
  # Returns { data: '{ "json": "stuff" }', etag: 'some-etag' }
  def get(key, maybe_param, maybe_etag)
    case key
    when :pollster_primaries
      throw ArgumentError.new('param must be "Dem" or "GOP"') if ![ 'Dem', 'GOP' ].include?(maybe_param)
      get_json!("http://elections.huffingtonpost.com/pollster/api/charts?topic=2016-president-#{maybe_param.downcase}-primary", maybe_etag)
    when :pollster_primary
      throw ArgumentError.new('param must be a slug-in-slug-format') if maybe_param.nil?
      get_json!("http://elections.huffingtonpost.com/pollster/api/charts/#{maybe_param}.json", maybe_etag)
    when :election_day
      throw ArgumentError.new('param must be a date in YYYY-MM-DD format') if maybe_param.nil?
      get_json!("https://api.ap.org/v2/elections/#{maybe_param}?level=ru&national=true&officeID=P&format=json&apikey=#{ap_api_key}#{is_test_query_param}#{is_zero_query_param}", maybe_etag)
    when :election_days
      throw ArgumentError.new('param must be nil') if !maybe_param.nil?
      get_json!("https://api.ap.org/v2/elections?format=json&apikey=#{ap_api_key}", maybe_etag)
    when :del_super
      throw ArgumentError.new('param must be nil') if !maybe_param.nil?
      # AP bug: ETag is always "0xfeed". Don't use ETag. Don't trust the docs.
      r1 = get_json!("https://api.ap.org/v2/reports?type=Delegates&subtype=delsuper&format=json&apikey=#{ap_api_key}#{is_test_query_param}", nil)

      report_id = Oj.load(r1[:data])['reports'][0]['id']
      r2 = get_json!("#{report_id}?format=json&apikey=#{ap_api_key}", nil) # no ETag, no "test" parameter

      { data: r2[:data], etag: r1[:etag] }
    else
      throw ArgumentError.new("invalid key #{key}")
    end
  end

  private

  # Fetches a JSON document from the server.
  #
  # Raises an error if the response code is not 200.
  # Raises an error if the response is not valid JSON.
  # Returns nil if the etag matches
  def get_json!(url, maybe_etag)
    response = @http_interface.get(url, maybe_etag)
    string = case response.code
    when '304' then nil
    when '200' then
      # AP returns a 200 OK on `/v2/reports?...` even when the etags match.
      # We *could* ignore those responses, or we *could* fiddle with
      # If-Modified-Since ... but that would be above and beyond the HTTP spec
      # and our API requirements, and we don't stand to gain anything, so let's
      # not.
      Oj.load(response.body) # Raise an error immediately on invalid JSON
      { data: response.body, etag: response['ETag'] }
    else raise "HTTP #{response.code} #{response.message} from server. Body: #{response.body}"
    end
  end

  def is_test_query_param
    is_test ? '&test=true' : ''
  end

  def is_zero_query_param
    is_zero ? '&setZeroCounts=true' : ''
  end
end
