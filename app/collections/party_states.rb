require_relative './collection_class'
require_relative '../models/party'

PartyStates = CollectionClass.new('party_states', 'party_state', PartyState)
