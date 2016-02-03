describe 'a Race table of candidates', type: :feature do
  def expand_list(page, race_id)
    el = page.first("##{race_id} button", text: /Show more/i)

    if !el # JavaScript hasn't put it there yet
      sleep 1
      el = page.first("##{race_id} button", text: /Show more/i)
    end

    el.click
  end

  def sheets_source_with_ap_says_its_over(bool)
    ret = Database.default_sheets_source
    ret.races.map! { |r| r.merge(ap_says_its_over: bool) }
    ret
  end

  context 'after a candidate has dropped out' do
    before(:all) do
      sheets_source = Database.default_sheets_source
      sheets_source.candidates.map! do |candidate|
        if candidate.full_name == 'Jim Gilmore'
          candidate.merge(dropped_out_date_or_nil: Date.parse('2016-02-01'))
        else
          candidate
        end
      end

      database = mock_database(
        '2016-02-01',
        '2016-02-09',
        sheets_source: sheets_source
      )

      require_relative '../../app/views/race_day_view'
      RaceDayView.generate_all(database)
    end

    it 'should show the candidate in races the candidate was in' do
      visit('/2016/primaries/2016-02-01')
      expand_list(page, 'IA-GOP')
      expect(page.first('td.candidate', text: 'Gilmore')).not_to be_nil
    end

    it 'should hide the candidate from races the candidate is not in' do
      visit('/2016/primaries/2016-02-09')
      expand_list(page, 'NH-GOP')
      expect(page.first('td.candidate', text: 'Gilmore')).to be_nil
    end
  end
end
