require 'csv'

require_relative './collection_class.rb'
require_relative '../models/state.rb'

States = CollectionClass.new('states', 'state', State) do
  def find_by_fips_int!(fips_int)
    @by_fips_int ||= all.map { |s| [ s.fips_int, s ] }.to_h
    @by_fips_int.fetch(fips_int.to_i)
  end

  def self.build_hard_coded(database)
    all = CSV.read(File.dirname(__FILE__) + '/states.csv')[1..-1]
      .each { |arr| [ 0, 4, 5 ].each { |i| arr[i] = arr[i].to_i } }
      .map { |arr| State.new(database, *arr) }
    self.new(all)
  end
end
