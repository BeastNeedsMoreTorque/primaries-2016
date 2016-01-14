describe 'the Race Day dashboard', type: :feature do
  context 'before we have even developed the page' do
    it 'should not render at all' do
      database = mock_database({}, '2016-01-31', '2016-02-09')
      render_from_database(database)

      visit('/2016/primaries/2016-03-01')
      expect(page.status_code).to eq(404)
    end
  end
end
