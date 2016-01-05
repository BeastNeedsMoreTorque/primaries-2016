require 'date'
require 'set'

require_relative './race'
require_relative './state'
require_relative '../../lib/ap'

class RaceDay
  def self.load_ap_data(ap_election_days)
    @@ap_election_days = ap_election_days.map{ |ed| [ ed[:electionDate], ed ] }.to_h
    # Initialize candidate names
    RaceDay.all.flat_map(&:races).each(&:candidate_races)
  end

  def initialize(static_hash)
    @static_hash = static_hash
    @ap_hash = @@ap_election_days[static_hash[:date]]
  end

  def id; @static_hash[:date]; end
  def date; Date.parse(@static_hash[:date]); end

  def parties # through races
    Party.all
      .select { |p| !!@static_hash[p.id.to_sym] }
  end

  def states # through races
    state_codes = Set.new(Party.all.flat_map{ |p| @static_hash[p.id.to_sym] || [] })
    State.all.select { |s| s.is_actual_state? && state_codes.include?(s.code.to_sym) }
  end

  def states_for_party(party)
    state_codes = (@static_hash[party.id.to_sym] || []).map { |code| State.find_by_code(code) }
  end

  def race_for_party_and_state(party, state)
    races.find { |r| r.party == party && r.state == state }
  end

  def races
    @races ||= if @ap_hash
      @ap_hash[:races].map do |race_hash|
        state_code = race_hash[:reportingUnits][0][:statePostal]
        state = State.find_by_code(state_code)
        party_id = race_hash[:party]
        party = Party.find_by_id(party_id)
        Race.new(self, party, state, race_hash)
      end
    else
      Party.all.map do |party|
        (@static_hash[party.id.to_sym] || []).map do |state_code|
          state = State.find_by_code(state_code)
          Race.new(self, party, state, nil)
        end
      end.flatten(1)
    end
  end

  def to_json(*a); @hash.to_json(*a); end

  def self.all
    @all ||= [
      { date: '2016-02-01', Dem: [ :IA ], GOP: [ :IA ] },
      { date: '2016-02-09', Dem: [ :NH ], GOP: [ :NH ] },
      { date: '2016-02-20', Dem: [ :NV ], GOP: [ :SC ] },
      { date: '2016-02-23', GOP: [ :NV ] },
      { date: '2016-02-27', Dem: [ :SC ] },
      { date: '2016-03-01',
        Dem: [ :AL, :AS, :AR, :CO, 'abroad', :GA, :MA, :MN, :OK, :TN, :TX, :VT, :VA ],
        GOP: [ :AL, :AK, :AR, :GA, :MA, :MN, :OK, :TN, :TX, :VT, :VA, :WY ] }, # CO isn't voting. http://www.denverpost.com/news/ci_28700919/colorado-republicans-cancel-2016-presidential-caucus-vote
      { date: '2016-03-05', Dem: [ :KS, :LA, :NE ], GOP: [ :KS, :KY, :LA, :ME ] },
      { date: '2016-03-06', Dem: [ :ME ], GOP: [ :PR ] },
      { date: '2016-03-08', Dem: [ :MI, :MS ], GOP: [ :HI, :ID, :MI, :MS ] },
      { date: '2016-03-12', Dem: [ :MP ], GOP: [ :DC, :GU, :WY ] },
      { date: '2016-03-15', Dem: [ :FL, :IL, :MO, :NC, :OH ], GOP: [ :FL, :IL, :MO, :NC, :MP, :OH ] },
      { date: '2016-03-19', GOP: [ :VI ] },
      { date: '2016-03-22', Dem: [ :AZ, :ID, :UT ], GOP: [ :AS, :AZ, :UT ] },
      { date: '2016-03-26', Dem: [ :AK, :HI, :WA ] },
      { date: '2016-04-01', GOP: [ :ND ] },
      { date: '2016-04-05', Dem: [ :WI ], GOP: [ :WI ] },
      { date: '2016-04-09', Dem: [ :WY ] },
      { date: '2016-04-16', GOP: [ :WY ] },
      { date: '2016-04-19', Dem: [ :NY ], GOP: [ :NY ] },
      { date: '2016-04-26', Dem: [ :CT, :DE, :MD, :PA, :RI ], GOP: [ :CT, :DE, :MD, :PA, :RI ] },
      { date: '2016-05-03', Dem: [ :IN ], GOP: [ :IN ] },
      { date: '2016-05-07', Dem: [ :GU ] },
      { date: '2016-05-10', Dem: [ :WV ], GOP: [ :NE, :WV ] }, # AP says Dem has NE, but it's an "advisory" race
      { date: '2016-05-17', Dem: [ :KY, :OR ], GOP: [ :OR ] },
      { date: '2016-05-24', Dem: [ :WA ], GOP: [ :WA ] },
      { date: '2016-06-04', Dem: [ :VI ] },
      { date: '2016-06-05', Dem: [ :PR ] },
      { date: '2016-06-07', Dem: [ :CA, :MT, :NJ, :NM, :ND, :SD ], GOP: [ :CA, :MT, :NJ, :NM, :SD ] },
      { date: '2016-06-14', Dem: [ :DC ] }
    ].map { |hash| RaceDay.new(hash) }
  end
end
