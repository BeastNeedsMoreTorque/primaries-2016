require_relative '../../app/models/database'
require_relative '../../app/views/race_day_view'
require_relative '../../app/views/race_day_results_view'

describe "calling races", type: :feature do
  it "should show the winner AP reports normally" do
    sheets_source = Database.default_sheets_source
    sheets_source.races.map! { |race| race.merge(huffpost_override_winner_last_name: nil) }

    ap_election_days_source = Database.default_ap_election_days_source
    ap_election_days_source.candidate_states.map! do |candidate_state|
      # Rand Paul is the only winner of all races
      candidate_state.merge(winner: candidate_state.candidate_id == '60208')
    end

    database = mock_database(
      '2016-02-01',
      '2016-02-01',
      sheets_source: sheets_source,
      ap_election_days_source: ap_election_days_source
    )

    RaceDayView.generate_all(database)
    RaceDayResultsView.generate_all(database)

    visit('/2016/primaries/2016-02-01')
    expect(page.find('tr', text: 'Paul').text).to match(/✓/)
  end

  it "should let HuffPost editors override the winner" do
    sheets_source = Database.default_sheets_source
    sheets_source.races.map! { |race| race.merge(huffpost_override_winner_last_name: 'Rubio') }

    ap_election_days_source = Database.default_ap_election_days_source
    ap_election_days_source.candidate_states.map! do |candidate_state|
      # Rand Paul is the only winner of all races
      candidate_state.merge(winner: candidate_state.candidate_id == '60208')
    end

    database = mock_database(
      '2016-02-01',
      '2016-02-01',
      sheets_source: sheets_source,
      ap_election_days_source: ap_election_days_source
    )

    RaceDayView.generate_all(database)
    RaceDayResultsView.generate_all(database)

    visit('/2016/primaries/2016-02-01')
    expect(page.find('tr', text: 'Paul').text).not_to match(/✓/)
    expect(page.find('tr', text: 'Rubio').text).to match(/✓/)
  end
end
