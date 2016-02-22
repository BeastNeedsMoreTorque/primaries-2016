require_relative '../../app/helpers/dot_group_helper'

describe DotGroupHelper do
  describe DotGroupHelper::BisectedDotGroups do
    include DotGroupHelper::HtmlMethods

    def render(*args); DotGroupHelper::BisectedDotGroups.new(*args).to_html; end

    it 'should render nothing when there are no dots' do
      expect(render('A', 0, 'B', 0)).to eq('')
    end

    it 'should render A when B is 0' do
      expect(render('A', 25, 'B', 0)).to eq(dot_group(dot_subgroup('A', dot_string(25))))
    end

    it 'should render two dot groups when A is too big for one' do
      expect(render('A', 26, 'B', 0)).to eq(dot_group(dot_subgroup('A', dot_string(25))) + dot_group(dot_subgroup('A', dot_string(1))))
    end

    it 'should render B when A is 0' do
      expect(render('A', 0, 'B', 25)).to eq(dot_group(dot_subgroup('B', dot_string(25))))
    end

    it 'should put A and B in the same dot group when possible' do
      expect(render('A', 13, 'B', 12)).to eq(dot_group(dot_subgroup('A', dot_string(13)) + dot_subgroup('B', dot_string(12))))
    end

    it 'should start B mid-dot-group' do
      expect(render('A', 13, 'B', 13)).to eq(dot_group(dot_subgroup('A', dot_string(13)) + dot_subgroup('B', dot_string(12))) + dot_group(dot_subgroup('B', dot_string(1))))
    end

    it 'should fill B into the correct dot-group size' do
      expect(render('A', 13, 'B', 25+12)).to eq(dot_group(dot_subgroup('A', dot_string(13)) + dot_subgroup('B', dot_string(12))) + dot_group(dot_subgroup('B', dot_string(25))))
    end

    it 'should extend B past two dot groups' do
      expect(render('A', 1, 'B', 50)).to eq(dot_group(dot_subgroup('A', dot_string(1)) + dot_subgroup('B', dot_string(24))) + dot_group(dot_subgroup('B', dot_string(25))) + dot_group(dot_subgroup('B', dot_string(1))))
    end
  end
end
