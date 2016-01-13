require 'ostruct'

Paths = OpenStruct.new({
  Assets: File.expand_path('../../assets', __FILE__),
  Templates: File.expand_path('../../app/templates', __FILE__),
  Cache: File.expand_path('../../cache', __FILE__),
  Dist: File.expand_path('../../dist', __FILE__),
  Root: File.expand_path('../..', __FILE__),
  Script: File.expand_path('../../script', __FILE__),
  Copy: File.expand_path('../../app/copy', __FILE__),
  ProductionDir: File.expand_path('../../tmp', __FILE__),
  ProductionCommands: File.expand_path('../../tmp/production-commands.sock', __FILE__),
  ProductionOutput: File.expand_path('../../tmp/production-output.sock', __FILE__)
})
