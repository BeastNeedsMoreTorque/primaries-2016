require 'fileutils'
require 'json'
require 'net/http'
require 'uri'

require_relative './ap_cache'
require_relative './ap_client'
require_relative './logger'
require_relative './paths'

# Requests data from the AP Elections API and stores it in `cache/ap`. Then
# returns it as JSON when requested.
module AP
  private

  def self.api_key
    raise 'You must set the AP_API_KEY environment variable' if !ENV['AP_API_KEY']
    ENV['AP_API_KEY']
  end

  def self.is_test
    !!ENV['AP_TEST']
  end

  public

  @server = APClient.new(APClient::HTTPClient.new, AP.api_key, AP.is_test)
  @cache = APCache.new(Paths.Cache)

  def self.wipe_all
    @cache.wipe_all
  end

  def self.poll_dates(dates)
    poll_or_fetch(:del_super, nil)
    #poll_or_fetch(:election_days, nil)
    for date in dates
      poll_or_fetch(:election_day, date)
    end
  end

  # Election results for the given date.
  #
  # Returns an ElectionDay or raises an error.
  def self.GET_primaries_election_day(date)
    string = get_cached_or_fetch(:election_day, date)
    parse_json(string)
  end

  # All 2016 election results.
  #
  # Returns an Array of ElectionDay objects.
  def self.GET_all_primary_election_days
    string = get_cached_or_fetch(:election_days, nil)
    obj = parse_json(string)
    obj[:elections]
      .select { |e| !!e[:testResults] == is_test }
      .map { |e| e[:electionDate] }
      .select { |d| d > '2016-00-00' && d < '2016-07-00' } # http://customersupport.ap.org/doc/eln/2016_Election_Calendar.pdf
      .map { |d| GET_primaries_election_day(d) }
  end

  # Delegate counts per candidate.
  #
  # Returns a DelSuper or raises an error.
  #
  # This performs two requests: first to /reports, and second to
  # /reports/id-returned-by-first-request.
  def self.GET_del_super
    string = get_cached_or_fetch(:del_super, nil)
    obj = parse_json(string)
    obj[:delSuper]
  end

  private

  # Polls @server for the latest version of this key using @cache etag, or
  # fetches on cache miss. Saves the return value to @cache.
  def self.poll_or_fetch(key, arg)
    existing = @cache.get(key, arg)
    etag = existing ? existing[:etag] : nil
    result = @server.get(key, arg, etag)
    if result[:etag] != etag
      @cache.save(key, arg, result[:data], result[:etag])
      result[:data]
    else
      existing[:data]
    end
  end

  def self.get_cached_or_fetch(key, arg)
    existing = @cache.get(key, arg)
    if existing
      existing[:data]
    else
      result = @server.get(key, arg, nil)
      @cache.save(key, arg, result[:data], result[:etag])
      result[:data]
    end
  end

  def self.parse_json(string)
    JSON.parse(string, create_additions: false, symbolize_names: true)
  end
end
