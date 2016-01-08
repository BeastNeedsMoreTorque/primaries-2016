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

  # Fetches a String document from the server and its String etag.
  #
  # Raises an error if the server does not respond.
  # Raises an error if the response code is not 200.
  # Raises an error if the response is not valid JSON.
  #
  # Returns { data: '{ "json": "stuff" }', etag: 'some-etag' }
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
      r1 = get!("/v2/reports?type=Delegates&subtype=delsuper&format=json&apikey=#{api_key}#{is_test_query_param}", maybe_etag)
      if r1 === nil
        # Exact same contents as before. And AP docs say report data at any
        # given URL remain constant, so we assume no change there
        nil
      else
        # We need to cache the ETag of the first response, because if it
        # matches we want to avoid making the second request completely.
        report_id = JSON.parse(r1[:data])['reports'][0]['id']['https://api.ap.org'.length .. -1]
        r2 = get!("#{report_id}?format=json&apikey=#{api_key}", nil) # no ETag, no "test" parameter
        { data: r2[:data], etag: r1[:etag] }
      end
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
    string = case response.code
    when '304' then nil
    when '200' then
      # AP returns a 200 OK on `/v2/reports?...` even when the etags match.
      # We *could* ignore those responses, or we *could* fiddle with
      # If-Modified-Since ... but that would be above and beyond the HTTP spec
      # and our API requirements, and we don't stand to gain anything, so let's
      # not.
      JSON.parse(response.body) # Raise an error immediately on invalid JSON
      { data: response.body, etag: response['ETag'] }
    else raise "HTTP #{response.code} #{response.message} from server. Body: #{response.body}"
    end
  end

  def is_test_query_param
    is_test ? '&test=true' : ''
  end
end
