require 'json'
require 'net/http'
require 'uri'

require_relative './logger'

class APClient
  class HTTPClient
    def get(url)
      $logger.debug("GET #{url}")
      uri = URI(url)
      Net::HTTP.get_response(uri)
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
  def get(key, maybe_param)
    case key
    when :election_day
      throw ArgumentError.new('param must be a date in YYYY-MM-DD format') if maybe_param.nil?
      get!("https://api.ap.org/v2/elections/#{maybe_param}?level=fipscode&national=true&officeID=P&format=json&apikey=#{api_key}#{is_test_query_param}")
    when :election_days
      throw ArgumentError.new('param must be nil') if !maybe_param.nil?
      get!("https://api.ap.org/v2/elections?format=json&apikey=#{api_key}")
    when :del_super
      throw ArgumentError.new('param must be nil') if !maybe_param.nil?
      s1 = get!("https://api.ap.org/v2/reports?type=Delegates&subtype=delsuper&format=json&apikey=#{api_key}#{is_test_query_param}")
      report_id = JSON.parse(s1)['reports'][0]['id']
      get!("#{report_id}?format=json&apikey=#{api_key}") # no "test" parameter
    else
      throw ArgumentError.new("invalid key #{key}")
    end
  end

  private

  # Fetches a JSON document from the server.
  #
  # Raises an error if the response code is not 200.
  # Raises an error if the response is not valid JSON.
  def get!(url)
    response = @http_client.get(url)
    raise "HTTP #{response.code} #{response.message} from server. Body: #{response.body}" if response.code != '200'
    JSON.parse(response.body) # raise an error early on invalid JSON
    response.body
  end

  def is_test_query_param
    is_test ? '&test=true' : ''
  end
end
