require 'fileutils'

require_relative '../lib/ap_cache'

RSpec.describe 'APCache' do
  before(:each) do
    @tmpdir = Dir.mktmpdir
    @subject = APCache.new(@tmpdir)
  end

  after(:each) do
    FileUtils.rm_rf(@tmpdir)
  end

  describe '#save' do
    it 'should require a valid key' do
      expect { @subject.save(:foo, nil, '""') }.to raise_error(ArgumentError)
    end

    it 'should require a date with :election_day' do
      expect { @subject.save(:election_day, '2015-12-22', '""') }.not_to raise_error
      expect { @subject.save(:election_day, nil, '""') }.to raise_error(ArgumentError)
    end

    it 'should require no date with :election_days and :del_super' do
      expect { @subject.save(:election_days, nil, '""') }.not_to raise_error
      expect { @subject.save(:election_days, '2015-12-22', '""') }.to raise_error(ArgumentError)
      expect { @subject.save(:del_super, nil, '""') }.not_to raise_error
      expect { @subject.save(:del_super, '2015-12-22', '""') }.to raise_error(ArgumentError)
    end

    it 'should save the given blob to a path without a param' do
      @subject.save(:election_days, nil, '"foo"')
      expect(IO.read("#{@tmpdir}/election_days")).to eq('"foo"')
    end

    it 'should save the given blob to a path with a param' do
      @subject.save(:election_day, '2015-12-22', '"foo"')
      expect(IO.read("#{@tmpdir}/election_day-2015-12-22")).to eq('"foo"')
    end

    it 'should create the directory if it is missing' do
      FileUtils.rm_rf(@tmpdir)
      @subject.save(:election_days, nil, '"foo"')
      expect(Dir.exist?(@tmpdir)).to be(true)
    end
  end

  describe '#get' do
    # These depend upon #save()

    it 'should return something saved with a param' do
      @subject.save(:election_day, '2015-12-22', '"foo"')
      expect(@subject.get(:election_day, '2015-12-22')).to eq('"foo"')
    end

    it 'should return something saved without a param' do
      @subject.save(:election_days, nil, '"foo"')
      expect(@subject.get(:election_days, nil)).to eq('"foo"')
    end

    it 'should return nil when the thing is not saved' do
      expect(@subject.get(:election_days, nil)).to be_nil
    end
  end

  describe '#get_or_update' do
    # relies on #save() and #get()
    it 'should #get()' do
      called = false
      @subject.save(:election_day, '2015-12-22', '"foo"')
      expect(@subject.get_or_update(:election_day, '2015-12-22')).to eq('"foo"')
      expect(called).to be(false)
    end

    it 'should call fetch_command if needed' do
      called = false
      ret = @subject.get_or_update(:election_day, '2015-12-22') do
        called = true
        '"foo"'
      end
      expect(ret).to eq('"foo"')
      expect(@subject.get(:election_day, '2015-12-22')).to eq('"foo"')
      expect(called).to be(true)
    end
  end

  describe '#wipe' do
    # relies on #save() and #get()

    it 'should wipe something with a param' do
      @subject.save(:election_day, '2015-12-22', '"foo"')
      @subject.wipe(:election_day, '2015-12-22')
      expect(@subject.get(:election_day, '2015-12-22')).to be_nil
    end

    it 'should wipe something without a param' do
      @subject.save(:election_days, nil, '"foo"')
      @subject.wipe(:election_days, nil)
      expect(@subject.get(:election_days, nil)).to be_nil
    end

    it 'should not wipe other things' do
      @subject.save(:election_days, nil, '"election_days"')
      @subject.save(:election_day, '2015-12-22', '"election_day-2015-12-22"')
      @subject.save(:election_day, '2015-12-23', '"election_day-2015-12-23"')
      @subject.wipe(:election_day, '2015-12-22')
      expect(@subject.get(:election_days, nil)).to eq('"election_days"')
      expect(@subject.get(:election_day, '2015-12-23')).to eq('"election_day-2015-12-23"')
    end
  end

  describe '#wipe_all' do
    it 'should remove the entire directory' do
      @subject.save(:election_days, nil, '"foo"')
      @subject.wipe_all
      expect(Dir.exist?(@tmpdir)).to be(false)
    end
  end
end
