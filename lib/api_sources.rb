require 'fileutils'
require 'oj'
require 'net/http'
require 'uri'

require_relative './http_cache'
require_relative './http_client'
require_relative './paths'

# Requests data from HTTP APIs: Pollster and AP.
#
# Stores results in `cache`.
#
# Returns JSON.
module ApiSources
  private

  def self.api_key
    raise 'You must set the AP_API_KEY environment variable' if !ENV['AP_API_KEY']
    ENV['AP_API_KEY']
  end

  def self.is_test
    !!ENV['AP_TEST']
  end

  def self.is_zero
    !!ENV['AP_ZERO']
  end

  public

  @server = HttpClient.new(HttpClient::HttpInterface.new, ApiSources.api_key, ApiSources.is_test, ApiSources.is_zero)
  @cache = HttpCache.new(Paths.Cache)

  def self.wipe_all
    @cache.wipe_all
  end

  def self.poll_del_super
    poll_or_fetch(:del_super, nil)
  end

  def self.poll_dates(dates)
    #poll_or_fetch(:election_days, nil)
    for date in dates
      poll_or_fetch(:election_day, date)
    end
  end

  def self.poll_pollster_primaries
    for party_id in %w(Dem GOP)
      string = poll_or_fetch(:pollster_primaries, party_id)
      json = parse_json(string)
      for chart_json in json
        slug = chart_json[:slug]
        poll_or_fetch(:pollster_primary, slug)
      end
    end
  end

  # Election results for the given date.
  def self.GET_primaries_election_day(date)
    string = get_cached_or_fetch(:election_day, date)
    parse_json(string)
  end

  # All 2016 election results.
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
  # This performs two requests: first to /reports, and second to
  # /reports/id-returned-by-first-request.
  def self.GET_del_super
    string = get_cached_or_fetch(:del_super, nil)
    obj = parse_json(string)

    set_del_super_numbers_to_zero(obj) if is_zero

    obj[:delSuper]
  end

  # Pollster primaries polling results per state, including 'US' state.
  def self.GET_pollster_primaries(party_id)
    string = get_cached_or_fetch(:pollster_primaries, party_id)
    parse_json(string)
  end

  # Pollster JSON for a single poll
  def self.GET_pollster_primary(slug)
    string = get_cached_or_fetch(:pollster_primary, slug)
    parse_json(string)
  end

  private

  # Recursively mutates a Hash, changing all nested :dTot and :sdTot to 0.
  #
  # Rationale: AP provides wrong official data and wrong test data before the
  # first race. And its Numbers are of the wrong type: they're Strings when
  # they should be Numbers. Except candidate IDs, which should be Strings.
  def self.set_del_super_numbers_to_zero(hash)
    hash.each do |k,v|
      if v.is_a?(Hash)
        set_del_super_numbers_to_zero(v)
      elsif v.is_a?(Array)
        v.map { |w| set_del_super_numbers_to_zero(w) }
      elsif k == :dTot
        hash[k] = '0'
      elsif k == :sdTot
        hash[k] = '0'
      end
    end
  end

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
    Oj.load(string, symbol_keys: true)
  end
end
