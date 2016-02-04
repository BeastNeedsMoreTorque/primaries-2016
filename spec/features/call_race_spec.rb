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
    expect(page.find('tr', text: 'Paul')[:class]).to match(/\bwinner\b/)
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
    expect(page.find('tr', text: 'Paul')[:class]).not_to match(/\bwinner\b/)
    expect(page.find('tr', text: 'Rubio')[:class]).to match(/\bwinner\b/)
  end

  it "should mark to the winner in JavaScript as results come in" do
    sheets_source = Database.default_sheets_source
    sheets_source.races.map! { |race| race.merge(huffpost_override_winner_last_name: nil) }

    ap_election_days_source = Database.default_ap_election_days_source
    ap_election_days_source.candidate_states.map! do |candidate_state|
      candidate_state.merge(winner: false)
    end

    database = mock_database(
      '2016-02-01',
      '2016-02-01',
      sheets_source: sheets_source,
      ap_election_days_source: ap_election_days_source
    )

    RaceDayView.generate_all(database) # HTML: no winner

    sheets_source.races.map! { |race| race.merge(huffpost_override_winner_last_name: 'Paul') }
    database2 = mock_database(
      '2016-02-01',
      '2016-02-01',
      sheets_source: sheets_source,
      ap_election_days_source: ap_election_days_source
    )
    RaceDayResultsView.generate_all(database2) # JSON: Rand Paul is the winner

    visit('/2016/primaries/2016-02-01')
    loop until page.evaluate_script('!jQuery.active')
    expect(page.find('tr', text: 'Paul')[:class]).to match(/\bwinner\b/)
  end
end
