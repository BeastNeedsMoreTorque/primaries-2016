CountyParty = Struct.new(:database, :fips_int, :party_id, :n_precincts_reporting, :n_precincts_total, :last_updated) do
  def find_all_by_party_id_and_state_fips_int(party_id, state_fips_int)
    @by_party_id_and_state_fips_int ||= all.group_by { |cp| "#{cp.party_id}-#{cp.fips_int / 1000}" }
    @by_party_id_and_state_fips_int["#{party_id}-#{state_fips_int}"]
  end
end
