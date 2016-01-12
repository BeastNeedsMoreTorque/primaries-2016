require_relative '../../app/models/database'

describe 'User navigates with a calendar', type: :feature do
  context 'before the first primaries, user wants a preview' do
    it 'should link to the next race day' do
      database = mock_database({}, '2016-01-31')
      render_from_database(database)

      visit('/2016/primaries')
      page.first('a', text: '1').click
      expect(page).to have_current_path('/2016/primaries/2016-02-01')
    end
  end
end
