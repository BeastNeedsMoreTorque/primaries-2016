require_relative './collection_class'
require_relative '../models/county_party'

CountyParties = CollectionClass.new('county_parties', 'county_party', CountyParty) do
  def find_all_by_party_id_and_state_fips_int(party_id, state_fips_int)
    @by_party_id_and_state_fips_int = all.group_by { |cc| "#{cc.party_id}-#{cc.fips_int / 1000}" }
    @by_party_id_and_state_fips_int["#{party_id}-#{state_fips_int}"]
  end
end
