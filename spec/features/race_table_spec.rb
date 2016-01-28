describe 'a Race table of candidates', type: :feature do
  context 'after a candidate has dropped out' do
    before(:each) do
      database = Database.load(override_copy: {
        'candidates.name=Jim Gilmore.dropped out' => '2016-02-01'
      })

      require_relative '../../app/views/race_day_view'
      RaceDayView.generate_all(database)
    end

    it 'should show the candidate in races the candidate was in' do
      visit('/2016/primaries/2016-02-01')
      page.first('#IA-GOP button', text: /Show more/i).click
      expect(page.first('td.candidate', text: 'Gilmore')).not_to be_nil
    end

    it 'should hide the candidate from races the candidate is not in' do
      visit('/2016/primaries/2016-02-09')
      page.first('#NH-GOP button', text: /Show more/i).click
      expect(page.first('td.candidate', text: 'Gilmore')).to be_nil
    end
  end
end
