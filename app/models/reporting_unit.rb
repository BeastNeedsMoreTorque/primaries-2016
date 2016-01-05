class ReportingUnit
#  def initialize(ap_hash); @ap_hash = hash; end
#
#  def fips_code; @hash[:FIPSCode]; end
#  def fips_int; fips_code.to_i; end # don't worry, Ruby doesn't do octal stuff here
#  def last_updated; DateTime.parse(@hash[:lastUpdated]); end
#  def level; @hash[:level]; end
#  def name; @hash[:name]; end
#  def n_precincts_reporting; @hash[:precinctsReporting]; end
#  def n_precincts_total; @hash[:precinctsTotal]; end
#
#  def candidates; @hash[:candidates].map { |c| Candidate.new(c) }; end
#  def last_updated; DateTime.parse(@hash[:lastUpdated]); end
#  def level; @hash[:level]; end
#  def name; @hash[:name]; end
#  def precincts_reporting; @hash[:precinctsReporting]; end
#  def precincts_total; @hash[:precinctsTotal]; end
#  def state_name; @hash[:stateName]; end
#  def state_postal; @hash[:statePostal]; end
end
