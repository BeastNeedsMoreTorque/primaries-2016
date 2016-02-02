require_relative './collection_class.rb'
require_relative '../models/party.rb'

Parties = CollectionClass.new('parties', 'party', Party)
