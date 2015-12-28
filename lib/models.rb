require 'date'

# http://customersupport.ap.org/doc/eln/AP_Elections_API_Developer_Guide.pdf

class Database
  attr_reader(:delegate_counts, :election_days)

  def initialize(delegate_counts, election_days)
    @delegate_counts = delegate_counts
    @election_days = election_days
  end

  def races
    @races ||= @election_days.flat_map(&:races)
  end

  # An Array of Pols.
  #
  # A Pol appears in this Array if he or she appears in the delegate_counts.
  def pols(party_id)
    @delegate_counts.party_country_candidates[party_id].values.map { |dc| Pol.new(dc, races) }
  end
end

# Politician
class Pol
  def initialize(del_candidate, races)
    @del_candidate = del_candidate
    @races = races
  end

  def id; @del_candidate.id; end
  def party_id; @del_candidate.party_id; end
  def n_delegates; @del_candidate.delegates; end
  def n_unpledged_delegates; @del_candidate.unpledged_delegates; end

  def n_votes
    race_candidates.map(&:vote_count).reduce(0, :+)
  end

  def name
    # Assume the name is the same across all races
    race_candidates.first.name || ''
  end

  private

  # Array of Candidates, one per Race this pol appears in
  def race_candidates
    @race_candidates ||= @races
      .select { |r| r.party == party_id }
      .flat_map { |r| r.state_reporting_units }
      .flat_map { |ru| ru.candidates.select { |c| c.pol_id == id } }
  end
end

class ElectionDay
  def initialize(hash); @hash = hash; end

  # JSON attributes, no logic
  def date; Date.parse(@hash[:electionDate]); end
  def timestamp; DateTime.parse(@hash[:timestamp]); end
  def races; @hash[:races].map { |r| Race.new(self, r) }; end
end

class Race
  attr_reader(:election_day)

  def initialize(election_day, hash)
    @election_day = election_day
    @hash = hash
  end

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
    @state_reporting_units ||= reporting_units.select { |ru| ru.level == 'state' }
  end
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

class DelSuper
  def initialize(hash); @hash = hash; end

  # JSON attributes, no logic
  def timestamp; DateTime.parse(@hash[:timestamp]); end
  def dels; @hash[:del].map { |d| Del.new(d) }; end

  # Derived

  # party_state_candidates[party_id][state_id][candidate_id] is a DelCandidate
  def party_state_candidates
    @party_state_candidates ||= build_party_state_candidates
  end

  # party_country_candidates[party_id][candidate_id] is a DelCandidate
  def party_country_candidates
    @country ||= build_party_country_candidates
  end

  private

  def build_party_state_candidates
    ret = {}
    for del in dels
      ret[del.party_id] = retDel = {}
      for state in del.states
        next if state.id == 'US'
        retDel[state.id] = retState = {}
        for candidate in state.candidates
          retState[candidate.id] = candidate
        end
      end
    end
    ret
  end

  def build_party_country_candidates
    ret = {}
    for del in dels
      ret[del.party_id] = retDel = {}
      for state in del.states
        if state.id == 'US'
          for candidate in state.candidates
            retDel[candidate.id] = candidate
          end
        end
      end
    end
    ret
  end
end

class Del
  def initialize(hash); @hash = hash; end

  # JSON attributes, no logic
  def party_id; @hash[:pId]; end
  def delegates_needed; @hash[:dNeed]; end
  def delegates_total; @hash[:dVote]; end
  def states; @hash[:State].map { |s| DelState.new(self, s) }; end
end

class DelState
  def initialize(del, hash); @del = del; @hash = hash; end

  # JSON attributes, no logic
  def id; @hash[:sId]; end
  def candidates; @hash[:Cand].map { |c| DelCandidate.new(@del, c) }; end
end

class DelCandidate
  def initialize(del, hash); @del = del; @hash = hash; end

  # JSON attributes, no logic
  def id; @hash[:cId]; end
  def name; @hash[:cName]; end
  def delegates; @hash[:dTot].to_i; end
  def unpledged_delegates; @hash[:sdTot].to_i; end

  def party_id; @del.party_id; end
end
