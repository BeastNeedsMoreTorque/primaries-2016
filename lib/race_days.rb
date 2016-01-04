require 'date'

require_relative './states'

class RaceDay
  def initialize(hash); @hash = hash; end
  def date; @hash[:date]; end

  def states
    arr = [ :Dem, :GOP ].map do |party|
      [ party, (@hash[party] || []).map { |code| StatesByCode[code] } ]
    end
    Hash[arr]
  end

  def to_json(*a); @hash.to_json(*a); end
end

RaceDays = [
  { date: Date.parse('2016-02-01'), Dem: [ 'IA' ], GOP: [ 'IA' ] },
  { date: Date.parse('2016-02-09'), Dem: [ 'NH' ], GOP: [ 'NH' ] },
  { date: Date.parse('2016-02-20'), Dem: [ 'NV' ], GOP: [ 'SC' ] },
  { date: Date.parse('2016-02-23'), GOP: [ 'NV' ] },
  { date: Date.parse('2016-02-27'), Dem: [ 'SC' ] },
  { date: Date.parse('2016-03-01'),
    Dem: [ 'AL', 'AS', 'AR', 'CO', 'abroad', 'GA', 'MA', 'MN', 'OK', 'TN', 'TX', 'VT', 'VA' ],
    GOP: [ 'AL', 'AK', 'AR', 'CO', 'GA', 'MA', 'MN', 'OK', 'TN', 'TX', 'VT', 'VA', 'WY' ] },
  { date: Date.parse('2016-03-05'), Dem: [ 'KS', 'LA', 'NE' ], GOP: [ 'KS', 'KY', 'LA', 'ME' ] },
  { date: Date.parse('2016-03-06'), Dem: [ 'ME' ], GOP: [ 'PR' ] },
  { date: Date.parse('2016-03-08'), Dem: [ 'MI', 'MS' ], GOP: [ 'HI', 'ID', 'MI', 'MS' ] },
  { date: Date.parse('2016-03-12'), Dem: [ 'MP' ], GOP: [ 'DC', 'GU', 'WY' ] },
  { date: Date.parse('2016-03-15'), Dem: [ 'FL', 'IL', 'MO', 'NC', 'OH' ], GOP: [ 'FL', 'IL', 'MO', 'NC', 'MP', 'OH' ] },
  { date: Date.parse('2016-03-19'), GOP: [ 'VI' ] },
  { date: Date.parse('2016-03-22'), Dem: [ 'AZ', 'ID', 'UT' ], GOP: [ 'AS', 'AZ', 'UT' ] },
  { date: Date.parse('2016-03-26'), Dem: [ 'AK', 'HI', 'WA' ] },
  { date: Date.parse('2016-04-01'), GOP: [ 'ND' ] },
  { date: Date.parse('2016-04-05'), Dem: [ 'WI' ], GOP: [ 'WI' ] },
  { date: Date.parse('2016-04-09'), Dem: [ 'WY' ] },
  { date: Date.parse('2016-04-16'), GOP: [ 'WY' ] },
  { date: Date.parse('2016-04-19'), Dem: [ 'NY' ], GOP: [ 'NY' ] },
  { date: Date.parse('2016-04-26'), Dem: [ 'CT', 'DE', 'MD', 'PA', 'RI' ], GOP: [ 'CT', 'DE', 'MD', 'PA', 'RI' ] },
  { date: Date.parse('2016-05-03'), Dem: [ 'IN' ], GOP: [ 'IN' ] },
  { date: Date.parse('2016-05-07'), Dem: [ 'GU' ] },
  { date: Date.parse('2016-05-10'), Dem: [ 'WV' ], GOP: [ 'NE', 'WV' ] }, # AP says Dem has NE, but it's an "advisory" race
  { date: Date.parse('2016-05-17'), Dem: [ 'KY', 'OR' ], GOP: [ 'OR' ] },
  { date: Date.parse('2016-05-24'), Dem: [ 'WA' ], GOP: [ 'WA' ] },
  { date: Date.parse('2016-06-04'), Dem: [ 'VI' ] },
  { date: Date.parse('2016-06-05'), Dem: [ 'PR' ] },
  { date: Date.parse('2016-06-07'), Dem: [ 'CA', 'MT', 'NJ', 'NM', 'ND', 'SD' ], GOP: [ 'CA', 'MT', 'NJ', 'NM', 'SD' ] },
  { date: Date.parse('2016-06-14'), Dem: [ 'DC' ], GOP: [ 'DC' ] }
].map { |hash| RaceDay.new(hash) }
