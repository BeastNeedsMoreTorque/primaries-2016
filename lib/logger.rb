require 'logger'

$logger = Logger.new(STDERR)
$logger.level = Logger.const_get((ENV['LOG_LEVEL'] || 'INFO').upcase)
