require_relative '../../app/views/primaries_splash_view'
require_relative '../../app/views/primaries_splash_results_view'

describe 'The splash banner', type: :feature do
  def ap_election_days_source_with_precincts_reporting(n_reporting, n_total)
    source = Database.default_ap_election_days_source
    source.races.map! { |race| race.merge(n_precincts_reporting: n_reporting, n_precincts_total: n_total) }
    source
  end

  def ap_election_days_source_with_winner(candidate_id)
    source = Database.default_ap_election_days_source
    source.candidate_races.map! { |cr| cr.merge(ap_says_winner: (candidate_id == cr.candidate_id), huffpost_says_winner: false) }
    source
  end

  def quick_database(n_reporting, n_total)
    mock_database(
      '2016-02-01',
      '2016-02-01',
      focus_race_day_id: '2016-02-01',
      ap_election_days_source: ap_election_days_source_with_precincts_reporting(n_reporting, n_total)
    )
  end

  def winner_database(candidate_id)
    mock_database(
      '2016-02-01',
      '2016-02-01',
      focus_race_day_id: '2016-02-01',
      ap_election_days_source: ap_election_days_source_with_winner(candidate_id)
    )
  end

  it 'should show precincts reporting in HTML' do
    PrimariesSplashView.generate_all(quick_database(10, 100))

    visit('/2016/primaries/splash')
    expect(page.first('.precincts', visible: true).text).to eq('10% of precincts reporting')
  end

  it 'should update precincts reporting from JSON' do
    PrimariesSplashView.generate_all(quick_database(10, 100))
    PrimariesSplashResultsView.generate_all(quick_database(12, 100))

    visit('/2016/primaries/splash')
    loop until page.evaluate_script('!jQuery.active')
    expect(page.first('.precincts', visible: true).text).to eq('12% of precincts reporting')
  end

  it 'should show <1% precincts reporting in HTML' do
    PrimariesSplashView.generate_all(quick_database(1, 200))
    visit('/2016/primaries/splash')
    expect(page.first('.precincts', visible: true).text).to eq('<1% of precincts reporting')
  end

  it 'should show <1% precincts reporting from JSON' do
    PrimariesSplashView.generate_all(quick_database(0, 200))
    PrimariesSplashResultsView.generate_all(quick_database(1, 200))
    visit('/2016/primaries/splash')
    loop until page.evaluate_script('!jQuery.active')
    expect(page.first('.precincts', visible: true).text).to eq('<1% of precincts reporting')
  end

  it 'should show >99% of precincts reporting in HTML' do
    PrimariesSplashView.generate_all(quick_database(199, 200))
    visit('/2016/primaries/splash')
    expect(page.first('.precincts', visible: true).text).to eq('>99% of precincts reporting')
  end

  it 'should show >99% precincts reporting from JSON' do
    PrimariesSplashView.generate_all(quick_database(198, 200))
    PrimariesSplashResultsView.generate_all(quick_database(199, 200))
    visit('/2016/primaries/splash')
    loop until page.evaluate_script('!jQuery.active')
    expect(page.first('.precincts', visible: true).text).to eq('>99% of precincts reporting')
  end

  it 'should mark the winner in HTML' do
    PrimariesSplashView.generate_all(winner_database('1746'))
    visit('/2016/primaries/splash')
    expect(page.first('tr.winner .candidate-name').text).to eq('Clinton')
  end

  it 'should mark the winner from JSON' do
    PrimariesSplashView.generate_all(winner_database(nil))
    PrimariesSplashResultsView.generate_all(winner_database('1746'))
    visit('/2016/primaries/splash')
    loop until page.evaluate_script('!jQuery.active')
    expect(page.first('tr.winner .candidate-name').text).to eq('Clinton')
  end
end
