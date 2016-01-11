require_relative './collection_class.rb'
require_relative '../models/party.rb'

Parties = CollectionClass.new('parties', 'party', Party) do
  def self.build_hard_coded(database)
    self.build(database, [
      [ :Dem, 'Democrats', 'Democratic' ],
      [ :GOP, 'Republicans', 'Republican' ]
    ])
  end
end
