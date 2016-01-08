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
      expect { @subject.save(:foo, nil, '""', 'etag') }.to raise_error(ArgumentError)
    end

    it 'should require a date with :election_day' do
      expect { @subject.save(:election_day, '2015-12-22', '""', 'etag') }.not_to raise_error
      expect { @subject.save(:election_day, nil, '""', 'etag') }.to raise_error(ArgumentError)
    end

    it 'should require no date with :election_days and :del_super' do
      expect { @subject.save(:election_days, nil, '""', 'etag') }.not_to raise_error
      expect { @subject.save(:election_days, '2015-12-22', '""', 'etag') }.to raise_error(ArgumentError)
      expect { @subject.save(:del_super, nil, '""', 'etag') }.not_to raise_error
      expect { @subject.save(:del_super, '2015-12-22', '""', 'etag') }.to raise_error(ArgumentError)
    end

    it 'should save the given blob to a path without a param' do
      @subject.save(:election_days, nil, '"foo"', 'etag')
      expect(IO.read("#{@tmpdir}/election_days")).to eq('"foo"')
    end

    it 'should save the given blob to a path with a param' do
      @subject.save(:election_day, '2015-12-22', '"foo"', 'etag')
      expect(IO.read("#{@tmpdir}/election_day-2015-12-22")).to eq('"foo"')
    end

    it 'should create the directory if it is missing' do
      FileUtils.rm_rf(@tmpdir)
      @subject.save(:election_days, nil, '"foo"', 'etag')
      expect(Dir.exist?(@tmpdir)).to be(true)
    end
  end

  describe '#get' do
    # These depend upon #save()

    it 'should return something saved with a param' do
      @subject.save(:election_day, '2015-12-22', '"foo"', 'etag')
      expect(@subject.get(:election_day, '2015-12-22')).to eq({ data: '"foo"', etag: 'etag' })
    end

    it 'should return something saved without a param' do
      @subject.save(:election_days, nil, '"foo"', 'etag')
      expect(@subject.get(:election_days, nil)).to eq({ data: '"foo"', etag: 'etag' })
    end

    it 'should return nil when the thing is not saved' do
      expect(@subject.get(:election_days, nil)).to be_nil
    end
  end

  describe '#wipe_all' do
    it 'should remove the entire directory' do
      @subject.save(:election_days, nil, '"foo"', 'etag')
      @subject.wipe_all
      expect(Dir.exist?(@tmpdir)).to be(false)
    end
  end
end
