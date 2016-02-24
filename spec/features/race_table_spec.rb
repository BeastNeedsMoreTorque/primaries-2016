describe 'a Race table of candidates', type: :feature do
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

      @database = mock_database(
        '2016-02-01',
        '2016-02-09',
        sheets_source: sheets_source
      )
    end

    before(:each) do
      require_relative '../../app/views/race_day_view'
      RaceDayView.generate_all(@database)
    end

    it 'should show the candidate in races the candidate was in' do
      visit('/2016/primaries/2016-02-01')
      expect(page.first('td.candidate', text: 'Gilmore')).not_to be_nil
    end

    it 'should hide the candidate from races the candidate is not in' do
      visit('/2016/primaries/2016-02-09')
      expect(page.first('td.candidate', text: 'Gilmore')).to be_nil
    end
  end
end
