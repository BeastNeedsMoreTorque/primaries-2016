require 'set'

# Saves and fetches raw JSON objects from the AP Elections API.
#
# They're saved to disk, in `base_path`.
class HttpCache
  ValidKeys = Set[:election_day, :election_days, :del_super, :pollster_primaries]
  ValidKeysWithoutParam = Set[:election_days, :del_super]
  ValidKeysWithParam = Set[:election_day, :pollster_primaries]

  def initialize(base_path)
    @base_path = base_path
  end

  def get(key, maybe_param)
    filename = args_to_filename(key, maybe_param)
    begin
      data = IO::read(filename)
      etag = IO::read("#{filename}.etag")
      $logger.debug("Cache hit: #{key},#{maybe_param}")
      { data: data, etag: etag }
    rescue Errno::ENOENT
      $logger.debug("Cache miss: #{key},#{maybe_param}")
      nil
    end
  end

  # Writes the given blob to the given key+param slot.
  def save(key, maybe_param, blob, etag)
    $logger.debug("Cache write: #{key},#{maybe_param}")
    filename = args_to_filename(key, maybe_param)
    FileUtils.mkdir_p(File.dirname(filename))
    IO::write(filename, blob)
    IO::write("#{filename}.etag", etag)
  end

  def wipe_all
    $logger.debug("Cache wipe_all")
    FileUtils.rm_rf(@base_path)
  end

  private

  def args_to_filename(key, maybe_param)
    if !ValidKeys.include?(key)
      raise ArgumentError.new("Invalid key #{key}. Must be one of #{ValidKeys}")
    elsif ValidKeysWithoutParam.include?(key) && !maybe_param.nil?
      raise ArgumentError.new("Key #{key} requires a YYYY-MM-DD param, but you passed nil")
    elsif ValidKeysWithParam.include?(key) && maybe_param.nil?
      raise ArgumentError.new("Key #{key} does not take a param; you should give nil")
    else
      @base_path + '/' + key.to_s + (maybe_param.nil? ? '' : "-#{maybe_param}")
    end
  end
end
