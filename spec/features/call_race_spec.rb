require_relative '../../app/models/database'
require_relative '../../app/views/race_day_view'
require_relative '../../app/views/race_day_results_view'

describe "calling races", type: :feature do
  def ap_election_days_source_with_winner(candidate_id)
    source = Database.default_ap_election_days_source
    source.candidate_races.map! { |cr| cr.merge(winner: cr.candidate_id == candidate_id) }
    source
  end

  def sheets_source_with_winner(last_name)
    source = Database.default_sheets_source
    source.races.map! { |race| race.merge(huffpost_override_winner_last_name: last_name) }
    source
  end

  def ap_election_days_source_without_winners
    source = Database.default_ap_election_days_source
    source.candidate_races.map! { |cr| cr.merge(winner: false) }
    source
  end

  def sheets_source_without_winners
    source = Database.default_sheets_source
    source.races.map! { |race| race.merge(huffpost_override_winner_last_name: nil) }
    source
  end

  it 'should show the winner AP reports normally' do
    database = mock_database(
      '2016-02-01',
      '2016-02-01',
      sheets_source: sheets_source_without_winners,
      ap_election_days_source: ap_election_days_source_with_winner('60208')
    )

    RaceDayView.generate_all(database)
    RaceDayResultsView.generate_all(database)

    visit('/2016/primaries/2016-02-01')
    expect(page.find('tr', text: 'Paul')[:class]).to match(/\bwinner\b/)
  end

  it 'should let HuffPost editors override the winner' do
    database = mock_database(
      '2016-02-01',
      '2016-02-01',
      sheets_source: sheets_source_with_winner('Rubio'),
      ap_election_days_source: ap_election_days_source_with_winner('60208')
    )

    RaceDayView.generate_all(database)
    RaceDayResultsView.generate_all(database)

    visit('/2016/primaries/2016-02-01')
    expect(page.find('tr', text: 'Paul')[:class]).not_to match(/\bwinner\b/)
    expect(page.find('tr', text: 'Rubio')[:class]).to match(/\bwinner\b/)
  end

  it 'should mark to the winner in JavaScript as results come in' do
    database = mock_database(
      '2016-02-01',
      '2016-02-01',
      sheets_source: sheets_source_without_winners,
      ap_election_days_source: ap_election_days_source_without_winners
    )

    RaceDayView.generate_all(database) # HTML: no winner

    database2 = mock_database(
      '2016-02-01',
      '2016-02-01',
      sheets_source: sheets_source_with_winner('Paul'),
      ap_election_days_source: ap_election_days_source_without_winners
    )
    RaceDayResultsView.generate_all(database2) # JSON: Rand Paul is the winner

    visit('/2016/primaries/2016-02-01')
    loop until page.evaluate_script('!jQuery.active')
    expect(page.find('tr', text: 'Paul')[:class]).to match(/\bwinner\b/)
  end
end
