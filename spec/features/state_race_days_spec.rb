require_relative '../../app/views/all_primaries_view'

describe 'The by-State list of dates on the primaries page', type: :feature do
  context 'before the first primaries, user wants a preview' do
    it 'should link to the next race day' do
      database = mock_database('2016-01-31', '2016-02-09')
      AllPrimariesView.generate_all(database)

      visit('/2016/primaries')
      page.first('a', text: 'Feb 1').click
      expect(page).to have_current_path('/2016/primaries/2016-02-01')
    end

    it 'should not link to dates past the end date' do
      database = mock_database('2016-01-31', '2016-02-09')
      AllPrimariesView.generate_all(database)

      visit('/2016/primaries')
      expect(page.first('a', text: 'Feb 20')).to be_nil # Feb. 20
      expect(page.first('span', text: 'Feb 20')).not_to be_nil
    end
  end
end
