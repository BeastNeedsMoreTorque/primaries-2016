describe 'a Race table of candidates', type: :feature do
  def expand_list(page, race_id)
    el = page.first("##{race_id} button", text: /Show more/i)

    if !el # JavaScript hasn't put it there yet
      sleep 1
      el = page.first("##{race_id} button", text: /Show more/i)
    end

    el.click
  end

  context 'after a candidate has dropped out' do
    before(:all) do
      database = Database.load(override_copy: {
        'candidates.name=Jim Gilmore.dropped out' => '2016-02-01'
      })

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
