require_relative '../../app/views/race_day_view'
require_relative '../../app/views/race_day_results_view'

describe 'a Race on the Race Day dashboard', type: :feature do
  it 'should have state=past when all precincts are reporting' do
    database = mock_database(
      { races: [ [ nil, '2016-02-01', 'Dem', 'IA', 'Caucus', 120, 120, DateTime.parse('2016-02-01'), nil, nil, nil ] ] },
      '2016-02-01',
      '2016-02-01',
      override_copy: {
        'primaries.races.state=IA,party=Dem.over' => ''
      }
    )
    RaceDayView.generate_all(database)
    RaceDayResultsView.generate_all(database)

    visit('/2016/primaries/2016-02-01')
    expect(page.first('#IA-Dem')['class']).to match(/\bpast\b/)
  end

  it 'should have state=future when 0 precincts are reporting' do
    database = mock_database(
      { races: [ [ nil, '2016-02-01', 'Dem', 'IA', 'Caucus', 0, 120, DateTime.parse('2016-02-01'), nil, nil, nil ] ] },
      '2016-02-01', '2016-02-01',
      override_copy: {
        'primaries.races.state=IA,party=Dem.over' => ''
      }
    )
    RaceDayView.generate_all(database)
    RaceDayResultsView.generate_all(database)

    visit('/2016/primaries/2016-02-01')
    expect(page.first('#IA-Dem')['class']).to match(/\bfuture\b/)
  end

  it 'should have state=present when at least one precinct is reporting' do
    database = mock_database(
      { races: [ [ nil, '2016-02-01', 'Dem', 'IA', 'Caucus', 1, 120, DateTime.parse('2016-02-01'), nil, nil, nil ] ] },
      '2016-02-01', '2016-02-01',
      override_copy: {
        'primaries.races.state=IA,party=Dem.over' => ''
      }
    )
    RaceDayView.generate_all(database)
    RaceDayResultsView.generate_all(database)

    visit('/2016/primaries/2016-02-01')
    expect(page.first('#IA-Dem')['class']).to match(/\bpresent\b/)
  end

  it 'should have state=past when the copy says over=true' do
    database = mock_database(
      { races: [ [ nil, '2016-02-01', 'Dem', 'IA', 'Caucus', 1, 120, DateTime.parse('2016-02-01'), nil, nil, nil ] ] },
      '2016-02-01', '2016-02-01',
      override_copy: {
        'primaries.races.state=IA,party=Dem.over' => 'true'
      }
    )
    RaceDayView.generate_all(database)
    RaceDayResultsView.generate_all(database)

    visit('/2016/primaries/2016-02-01')
    expect(page.first('#IA-Dem')['class']).to match(/\bpast\b/)
  end
end
