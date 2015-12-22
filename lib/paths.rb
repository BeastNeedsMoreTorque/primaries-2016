require 'ostruct'

Paths = OpenStruct.new({
  Assets: File.expand_path("../../assets", __FILE__),
  Cache: File.expand_path("../../cache", __FILE__),
  Dist: File.expand_path("../../dist", __FILE__),
  Root: File.expand_path("../..", __FILE__),
  Script: File.expand_path("../../script", __FILE__)
})
