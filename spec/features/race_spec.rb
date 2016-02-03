require_relative '../../app/views/race_day_view'
require_relative '../../app/views/race_day_results_view'

describe 'a Race on the Race Day dashboard', type: :feature do
  def sheets_source_with_ap_says_its_over(bool)
    ret = Database.default_sheets_source
    ret.races.map! { |r| r.merge(ap_says_its_over: bool) }
    ret
  end

  def ap_election_days_source_with_precincts(reporting, total)
    ret = Database.default_ap_election_days_source
    ret.races.map! { |r| r.merge(n_precincts_reporting: reporting, n_precincts_total: total) }
    ret
  end

  it 'should have state=past when all precincts are reporting' do
    database = mock_database(
      '2016-02-01',
      '2016-02-01',
      sheets_source: sheets_source_with_ap_says_its_over(false),
      ap_election_days: ap_election_days_source_with_precincts(120, 120)
    )
    RaceDayView.generate_all(database)
    RaceDayResultsView.generate_all(database)

    visit('/2016/primaries/2016-02-01')
    expect(page.first('#IA-Dem')['class']).to match(/\bpast\b/)
  end

  it 'should have state=future when 0 precincts are reporting' do
    database = mock_database(
      '2016-02-01',
      '2016-02-01',
      sheets_source: sheets_source_with_ap_says_its_over(false),
      ap_election_days: ap_election_days_source_with_precincts(0, 120)
    )
    RaceDayView.generate_all(database)
    RaceDayResultsView.generate_all(database)

    visit('/2016/primaries/2016-02-01')
    expect(page.first('#IA-Dem')['class']).to match(/\bfuture\b/)
  end

  it 'should have state=future when AP has no precinct counts' do
    database = mock_database(
      '2016-02-01',
      '2016-02-01',
      sheets_source: sheets_source_with_ap_says_its_over(false),
      ap_election_days: ap_election_days_source_with_precincts(nil, nil)
    )
    RaceDayView.generate_all(database)
    RaceDayResultsView.generate_all(database)

    visit('/2016/primaries/2016-02-01')
    expect(page.first('#IA-Dem')['class']).to match(/\bfuture\b/)
  end

  it 'should have state=present when at least one precinct is reporting' do
    database = mock_database(
      '2016-02-01',
      '2016-02-01',
      sheets_source: sheets_source_with_ap_says_its_over(false),
      ap_election_days: ap_election_days_source_with_precincts(1, 120)
    )
    RaceDayView.generate_all(database)
    RaceDayResultsView.generate_all(database)

    visit('/2016/primaries/2016-02-01')
    expect(page.first('#IA-Dem')['class']).to match(/\bpresent\b/)
  end

  it 'should have state=past when the sheet says over=true' do
    database = mock_database(
      '2016-02-01',
      '2016-02-01',
      sheets_source: sheets_source_with_ap_says_its_over(true),
      ap_election_days: ap_election_days_source_with_precincts(109, 120)
    )
    RaceDayView.generate_all(database)
    RaceDayResultsView.generate_all(database)

    visit('/2016/primaries/2016-02-01')
    expect(page.first('#IA-Dem')['class']).to match(/\bpast\b/)
  end
end
