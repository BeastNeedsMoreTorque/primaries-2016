CountyParty = Struct.new(:fips_code, :party_id, :n_precincts_reporting, :n_precincts_total, :last_updated) do
  def self.all=(v); @all = v; end
  def self.all; @all; end
end
