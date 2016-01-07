require 'date'
require 'set'

require_relative './state'

RaceDay = Struct.new(:id, :races_codified) do
  def date; Date.parse(id); end

  # States that have one or more races on this day
  def states
    state_codes = Set.new(races_codified.values.flatten.map(&:to_s))
    State.all.select{ |s| state_codes.include?(s.code) }.sort_by(&:name)
  end

  def states_for_party(party)
    state_codes = (races_codified[party.id.to_sym] || []).map(&:to_s)
    State.all.select{ |s| state_codes.include?(s.code) }.sort_by(&:name)
  end

  def self.find(id)
    @by_id ||= all.map{|rd| [ rd.id, rd ]}.to_h
    @by_id.fetch(id)
  end

  def self.all
    @all ||= [
      { date: '2016-02-01', races: { Dem: [ :IA ], GOP: [ :IA ] } },
      { date: '2016-02-09', races: { Dem: [ :NH ], GOP: [ :NH ] } },
      { date: '2016-02-20', races: { Dem: [ :NV ], GOP: [ :SC ] } },
      { date: '2016-02-23', races: { GOP: [ :NV ] } },
      { date: '2016-02-27', races: { Dem: [ :SC ] } },
      { date: '2016-03-01', races: {
        Dem: [ :AL, :AS, :AR, :CO, 'abroad', :GA, :MA, :MN, :OK, :TN, :TX, :VT, :VA ],
        GOP: [ :AL, :AK, :AR, :GA, :MA, :MN, :OK, :TN, :TX, :VT, :VA, :WY ] } }, # CO isn't voting. http://www.denverpost.com/news/ci_28700919/colorado-republicans-cancel-2016-presidential-caucus-vote
      { date: '2016-03-05', races: { Dem: [ :KS, :LA, :NE ], GOP: [ :KS, :KY, :LA, :ME ] } },
      { date: '2016-03-06', races: { Dem: [ :ME ], GOP: [ :PR ] } },
      { date: '2016-03-08', races: { Dem: [ :MI, :MS ], GOP: [ :HI, :ID, :MI, :MS ] } },
      { date: '2016-03-12', races: { Dem: [ :MP ], GOP: [ :DC, :GU, :WY ] } },
      { date: '2016-03-15', races: { Dem: [ :FL, :IL, :MO, :NC, :OH ], GOP: [ :FL, :IL, :MO, :NC, :MP, :OH ] } },
      { date: '2016-03-19', races: { GOP: [ :VI ] } },
      { date: '2016-03-22', races: { Dem: [ :AZ, :ID, :UT ], GOP: [ :AS, :AZ, :UT ] } },
      { date: '2016-03-26', races: { Dem: [ :AK, :HI, :WA ] } },
      { date: '2016-04-01', races: { GOP: [ :ND ] } },
      { date: '2016-04-05', races: { Dem: [ :WI ], GOP: [ :WI ] } },
      { date: '2016-04-09', races: { Dem: [ :WY ] } },
      { date: '2016-04-16', races: { GOP: [ :WY ] } },
      { date: '2016-04-19', races: { Dem: [ :NY ], GOP: [ :NY ] } },
      { date: '2016-04-26', races: { Dem: [ :CT, :DE, :MD, :PA, :RI ], GOP: [ :CT, :DE, :MD, :PA, :RI ] } },
      { date: '2016-05-03', races: { Dem: [ :IN ], GOP: [ :IN ] } },
      { date: '2016-05-07', races: { Dem: [ :GU ] } },
      { date: '2016-05-10', races: { Dem: [ :WV ], GOP: [ :NE, :WV ] } }, # AP says Dem has NE, but it's an "advisory" race
      { date: '2016-05-17', races: { Dem: [ :KY, :OR ], GOP: [ :OR ] } },
      { date: '2016-05-24', races: { Dem: [ :WA ], GOP: [ :WA ] } },
      { date: '2016-06-04', races: { Dem: [ :VI ] } },
      { date: '2016-06-05', races: { Dem: [ :PR ] } },
      { date: '2016-06-07', races: { Dem: [ :CA, :MT, :NJ, :NM, :ND, :SD ], GOP: [ :CA, :MT, :NJ, :NM, :SD ] } },
      { date: '2016-06-14', races: { Dem: [ :DC ] } }
    ].map { |hash| RaceDay.new(hash[:date], hash[:races]) }
  end
end
