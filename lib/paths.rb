require 'ostruct'

Paths = OpenStruct.new({
  Assets: File.expand_path("../../assets", __FILE__),
  Dist: File.expand_path("../../dist", __FILE__),
  Root: File.expand_path("../..", __FILE__)
})
