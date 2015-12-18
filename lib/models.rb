require 'date'

# http://customersupport.ap.org/doc/eln/AP_Elections_API_Developer_Guide.pdf

class ElectionDay
  def initialize(hash); @hash = hash; end

  # JSON attributes, no logic
  def date; Date.parse(@hash[:electionDate]); end
  def timestamp; DateTime.parse(@hash[:timestamp]); end
  def races; @hash[:races].map { |r| Race.new(r) }; end
end

class Race
  def initialize(hash); @hash = hash; end

  # JSON attributes, no logic
  def id; @hash[:raceID]; end
  def num_runoff; @hash[:numRunoff]; end
  def office_id; @hash[:officeID]; end
  def office_name; @hash[:officeName]; end
  def party; @hash[:party]; end
  def race_type; @hash[:raceType]; end
  def race_type_id; @hash[:raceTypeID]; end
  def reporting_units; (@hash[:reportingUnits] || []).map { |ru| ReportingUnit.new(ru) }; end

  # Derived values

  def state_reporting_units
    reporting_units.select { |ru| ru.level == 'state' }
  end

  private

  def sum(arr); arr.reduce(0) { |s, n| s + n }; end
end

class ReportingUnit
  def initialize(hash); @hash = hash; end

  # JSON attributes, no logic
  def id; @hash[:reportingunitID]; end
  def candidates; @hash[:candidates].map { |c| Candidate.new(c) }; end
  def fips_code; @hash[:FIPSCode]; end
  def last_updated; DateTime.parse(@hash[:lastUpdated]); end
  def level; @hash[:level]; end
  def name; @hash[:name]; end
  def precincts_reporting; @hash[:precinctsReporting]; end
  def precincts_total; @hash[:precinctsTotal]; end
  def state_name; @hash[:stateName]; end
  def state_postal; @hash[:statePostal]; end
end

class Candidate
  def initialize(hash); @hash = hash; end

  # JSON attributes, no logic
  def id; @hash[:candidateID]; end
  def ballot_order; @hash[:ballotOrder]; end
  def first; @hash[:first]; end
  def incumbent; @hash[:incumbent]; end
  def last; @hash[:last]; end
  def party; @hash[:party]; end
  def pol_id; @hash[:polID]; end
  def pol_num; @hash[:polNum]; end
  def vote_count; @hash[:voteCount]; end
  def winner; @hash[:winner]; end

  # Derived stuff
  def name
    "#{first} #{last}"
  end
end
