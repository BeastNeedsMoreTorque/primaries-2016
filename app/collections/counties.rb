require_relative './collection_class'
require_relative '../models/county'

Counties = CollectionClass.new('counties', 'county', County)
