require 'json'
require 'net/http'
require 'uri'

require_relative './models'

module AP
  # Requests election results for the given date.
  #
  # Returns an ElectionDay or raises an error.
  def self.GET_primaries_election_day(date)
    uri = URI("https://api.ap.org/v2/elections/#{date.to_s}?apikey=#{api_key}&level=ru&national=true&officeID=P&format=json#{is_test_query_param}")
    response = Net::HTTP.get_response(uri)
    raise "HTTP #{response.code} #{response.message} from server. Body: #{response.body}" if response.code != '200'
    obj = JSON.parse(response.body, create_additions: false, symbolize_names: true)
    ElectionDay.new(obj)
  end

  private

  def self.api_key
    raise 'You must set the AP_API_KEY environment variable' if !ENV['AP_API_KEY']
    ENV['AP_API_KEY']
  end

  def self.is_test_query_param
    ENV['AP_TEST'] ? '&test=true' : ''
  end
end
