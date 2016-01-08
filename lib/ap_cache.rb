require 'set'

# Saves and fetches raw JSON objects from the AP Elections API.
#
# They're saved to disk, in `base_path`.
class APCache
  ValidKeys = Set[:election_day, :election_days, :del_super]
  ValidKeysWithoutParam = Set[:election_days, :del_super]
  ValidKeysWithParam = Set[:election_day]

  def initialize(base_path)
    @base_path = base_path
  end

  def get(key, maybe_param)
    filename = args_to_filename(key, maybe_param)
    begin
      ret = IO::read(filename)
      $logger.debug("Cache hit: #{key},#{maybe_param}")
      ret
    rescue Errno::ENOENT
      $logger.debug("Cache miss: #{key},#{maybe_param}")
      nil
    end
  end

  def get_or_update(key, maybe_param, &fetch_command)
    ret = get(key, maybe_param)
    if !ret
      ret = fetch_command.call
      save(key, maybe_param, ret)
    end
    ret
  end

  # Writes the given blob to the given key+param slot.
  def save(key, maybe_param, blob)
    $logger.debug("Cache write: #{key},#{maybe_param}")
    filename = args_to_filename(key, maybe_param)
    FileUtils.mkdir_p(File.dirname(filename))
    IO::write(filename, blob)
  end

  def wipe(key, maybe_param)
    $logger.debug("Cache wipe: #{key},#{maybe_param}")
    filename = args_to_filename(key, maybe_param)
    FileUtils::rm_f(filename)
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
