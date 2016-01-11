require_relative './collection_class'
require_relative '../models/county_party'

CountyParties = CollectionClass.new('county_parties', 'county_party', CountyParty)
