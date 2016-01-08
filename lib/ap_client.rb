require 'json'
require 'net/http'
require 'uri'

require_relative './logger'

class APClient
  class HTTPClient
    def get(path, maybe_etag)
      uri = URI("https://api.ap.org#{path}")

      $logger.debug("GET #{uri}")

      req = Net::HTTP::Get.new(uri)
      req['If-None-Match'] = maybe_etag if maybe_etag

      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(req)
      end
    end
  end

  attr_reader(:api_key, :is_test)

  def initialize(http_client, api_key, is_test)
    @http_client = http_client
    @api_key = api_key
    @is_test = is_test
  end

  # Fetches a string document from the server.
  #
  # Raises an error if the server does not respond.
  # Raises an error if the response code is not 200.
  # Raises an error if the response is not valid JSON.
  def get(key, maybe_param, maybe_etag)
    case key
    when :election_day
      throw ArgumentError.new('param must be a date in YYYY-MM-DD format') if maybe_param.nil?
      get!("/v2/elections/#{maybe_param}?level=fipscode&national=true&officeID=P&format=json&apikey=#{api_key}#{is_test_query_param}", maybe_etag)
    when :election_days
      throw ArgumentError.new('param must be nil') if !maybe_param.nil?
      get!("/v2/elections?format=json&apikey=#{api_key}", maybe_etag)
    when :del_super
      throw ArgumentError.new('param must be nil') if !maybe_param.nil?
      s1 = get!("/v2/reports?type=Delegates&subtype=delsuper&format=json&apikey=#{api_key}#{is_test_query_param}", maybe_etag)
      report_id = JSON.parse(s1)['reports'][0]['id']['https://api.ap.org'.length .. -1]
      get!("#{report_id}?format=json&apikey=#{api_key}", maybe_etag) # no "test" parameter
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
  def get!(url, maybe_etag)
    response = @http_client.get(url, maybe_etag)
    case response.code
    when '304' then nil
    when '200' then JSON.parse(response.body); response.body # raise an error on invalid JSON, but return the original data
    else raise "HTTP #{response.code} #{response.message} from server. Body: #{response.body}"
    end
  end

  def is_test_query_param
    is_test ? '&test=true' : ''
  end
end
