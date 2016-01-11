require_relative './collection_class.rb'
require_relative '../models/party.rb'

Parties = CollectionClass.new('parties', 'party', Party) do
  def self.extra_attributes_by_id
    {
      Dem: {
        name: 'Democrats',
        adjective: 'Democratic'
      },
      GOP: {
        name: 'Republicans',
        adjective: 'Republican'
      }
    }
  end
end
