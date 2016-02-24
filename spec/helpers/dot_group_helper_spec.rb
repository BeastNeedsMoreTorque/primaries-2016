require_relative '../../app/helpers/dot_group_helper'

describe DotGroupHelper do
  describe '#group_dot_subgroups' do
    include DotGroupHelper

    def g(*subgroups); DotGroupHelper::DotGroupWithSubgroups.new(subgroups); end
    def sg(data, n); DotGroupHelper::DotSubgroup.new(data, n); end
    def go(*subgroups); group_dot_subgroups(subgroups).to_s; end

    it 'should render nothing when there are no dots' do
      expect(go()).to eq('')
    end

    it 'should put a dot in a group' do
      expect(go(sg('A', 1))).to eq('A:1')
    end

    it 'should fill a group with dots' do
      expect(go(sg('A', 25))).to eq('A:25')
    end

    it 'should split a subgroup into two groups' do
      expect(go(sg('A', 26))).to eq('A:25|A:1')
    end

    it 'should split a second subgroup correctly' do
      expect(go(sg('A', 10), sg('B', 26))).to eq('A:10 B:15|B:11')
    end

    it 'should split a third subgroup correctly, when each group only contains two subgroups' do
      expect(go(sg('A', 26), sg('B', 25), sg('C', 25))).to eq('A:25|A:1 B:24|B:1 C:24|C:1')
    end

    it 'should split a third subgroup correctly, when a group contains three subgroups' do
      expect(go(sg('A', 1), sg('B', 2), sg('C', 23))).to eq('A:1 B:2 C:22|C:1')
    end

    it 'should filter out 0-dot subgroups' do
      expect(go(sg('A', 1), sg('B', 0), sg('C', 1))).to eq('A:1 C:1')
    end
  end
end
