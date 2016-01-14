describe 'User navigates with a calendar', type: :feature do
  context 'before the first primaries, user wants a preview' do
    it 'should link to the next race day' do
      database = mock_database({}, '2016-01-31', '2016-02-09')
      render_from_database(database)

      visit('/2016/primaries/2016-02-09')
      page.first('.calendar a', text: '1').click
      expect(page).to have_current_path('/2016/primaries/2016-02-01')
    end

    it 'should not link to dates past the end date' do
      database = mock_database({}, '2016-01-31', '2016-02-09')
      render_from_database(database)

      visit('/2016/primaries/2016-02-09')
      expect(page.first('.calendar a', text: '20')).to be_nil # Feb. 20
      expect(page.first('.calendar span', text: '20')).not_to be_nil
    end
  end
end
