require_relative '../../app/views/primaries_splash_view'
require_relative '../../app/views/primaries_splash_results_view'

describe 'The splash banner', type: :feature do
  def ap_election_days_source_with_precincts_reporting(n_reporting, n_total)
    source = Database.default_ap_election_days_source
    source.races.map! { |race| race.merge(n_precincts_reporting: n_reporting, n_precincts_total: n_total) }
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
end
