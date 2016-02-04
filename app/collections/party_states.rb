require_relative './collection_class'
require_relative '../models/party_state'

PartyStates = CollectionClass.new('party_states', 'party_state', PartyState)
