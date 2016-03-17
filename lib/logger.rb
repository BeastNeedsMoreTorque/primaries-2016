require 'logger'

$logger = Logger.new(STDERR)
$logger.formatter = proc do |severity, datetime, progname, msg|
  "#{datetime.strftime('%FT%T.%3N')} #{severity[0]}: #{msg}\n"
end
$logger.level = Logger.const_get((ENV['LOG_LEVEL'] || 'INFO').upcase)
