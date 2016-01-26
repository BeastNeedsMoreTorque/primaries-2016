require_relative './collection_class'
require_relative '../models/race_day'

RaceDays = CollectionClass.new('race_days', 'race_day', RaceDay) do
  def self.build_hard_coded(database)
    arr = []

    RaceDays::HardCodedData.each do |date_sym, races|
      arr << RaceDay.new(database, date_sym.to_s, races)
    end

    self.new(arr)
  end
end

RaceDays::HardCodedData = {
  '2016-02-01': { Dem: [ :IA ], GOP: [ :IA ] },
  '2016-02-09': { Dem: [ :NH ], GOP: [ :NH ] },
  '2016-02-20': { Dem: [ :NV ], GOP: [ :SC ] },
  '2016-02-23': { GOP: [ :NV ] },
  '2016-02-27': { Dem: [ :SC ] },
  '2016-03-01': {
    Dem: [ :AL, :AS, :AR, :CO, :DA, :GA, :MA, :MN, :OK, :TN, :TX, :VT, :VA ],
    GOP: [ :AL, :AK, :AR, :GA, :MA, :MN, :OK, :TN, :TX, :VT, :VA, :WY ] }, # CO isn't voting. http://www.denverpost.com/news/ci_28700919/colorado-republicans-cancel-2016-presidential-caucus-vote
  '2016-03-05': { Dem: [ :KS, :LA, :NE ], GOP: [ :KS, :KY, :LA, :ME ] },
  '2016-03-06': { Dem: [ :ME ], GOP: [ :PR ] },
  '2016-03-08': { Dem: [ :MI, :MS ], GOP: [ :HI, :ID, :MI, :MS ] },
  '2016-03-12': { Dem: [ :MP ], GOP: [ :DC, :GU, :WY ] },
  '2016-03-15': { Dem: [ :FL, :IL, :MO, :NC, :OH ], GOP: [ :FL, :IL, :MO, :NC, :MP, :OH ] },
  '2016-03-19': { GOP: [ :VI ] },
  '2016-03-22': { Dem: [ :AZ, :ID, :UT ], GOP: [ :AS, :AZ, :UT ] },
  '2016-03-26': { Dem: [ :AK, :HI, :WA ] },
  '2016-04-01': { GOP: [ :ND ] },
  '2016-04-05': { Dem: [ :WI ], GOP: [ :WI ] },
  '2016-04-09': { Dem: [ :WY ] },
  '2016-04-16': { GOP: [ :WY ] },
  '2016-04-19': { Dem: [ :NY ], GOP: [ :NY ] },
  '2016-04-26': { Dem: [ :CT, :DE, :MD, :PA, :RI ], GOP: [ :CT, :DE, :MD, :PA, :RI ] },
  '2016-05-03': { Dem: [ :IN ], GOP: [ :IN ] },
  '2016-05-07': { Dem: [ :GU ] },
  '2016-05-10': { Dem: [ :WV ], GOP: [ :NE, :WV ] }, # AP says Dem has NE, but it's an "advisory" race
  '2016-05-17': { Dem: [ :KY, :OR ], GOP: [ :OR ] },
  '2016-05-24': { GOP: [ :WA ] }, # AP says Dem has WA, but it's 2016-03-26. WSJ and NYT agree
  '2016-06-04': { Dem: [ :VI ] },
  '2016-06-05': { Dem: [ :PR ] },
  '2016-06-07': { Dem: [ :CA, :MT, :NJ, :NM, :ND, :SD ], GOP: [ :CA, :MT, :NJ, :NM, :SD ] },
  '2016-06-14': { Dem: [ :DC ] }
}
