require 'oj'

require_relative '../lib/ap_client'

describe 'APClient' do
  before(:each) do
    @server = instance_double('APClient::HTTPClient')
    @subject = APClient.new(@server, 'abcdef', false)

    def expect_GET(path, maybe_etag, response, body)
      allow(response).to receive(:body).and_return(body)
      expect(@server).to receive(:get).with(path, maybe_etag).and_return(response)
    end
  end

  describe '#fetch' do
    it 'should fetch the election-days list JSON' do
      expect_GET('/v2/elections?format=json&apikey=abcdef', nil, Net::HTTPOK.new('1.1', '200', 'OK'), '{}')
      expect(@subject.get(:election_days, nil, nil)[:data]).to eq('{}')
    end

    it 'should fetch the election-day JSON' do
      expect_GET('/v2/elections/2015-12-22?level=fipscode&national=true&officeID=P&format=json&apikey=abcdef', nil, Net::HTTPOK.new('1.1', '200', 'OK'), '{}')
      expect(@subject.get(:election_day, '2015-12-22', nil)[:data]).to eq('{}')
    end

    it 'should fetch the del_super JSON' do
      expect_GET('/v2/reports?type=Delegates&subtype=delsuper&format=json&apikey=abcdef', nil, Net::HTTPOK.new('1.1', '200', 'OK'), '{"reports":[{"id":"https://api.ap.org/v2/reports/ghijkl"}]}')
      expect_GET('/v2/reports/ghijkl?format=json&apikey=abcdef', nil, Net::HTTPOK.new('1.1', '200', 'OK'), '{}')
      expect(@subject.get(:del_super, nil, nil)[:data]).to eq('{}')
    end

    it 'should raise an error if the server returns non-200' do
      expect_GET('/v2/reports?type=Delegates&subtype=delsuper&format=json&apikey=abcdef', nil, Net::HTTPNotFound.new('1.1', 404, 'Not Found'), '"Error: not found"')
      expect { @subject.get(:del_super, nil, nil) }.to raise_error(RuntimeError)
    end

    it 'should raise an error if the server returns non-JSON' do
      expect_GET('/v2/elections?format=json&apikey=abcdef', nil, Net::HTTPOK.new('1.1', '200', 'OK'), 'foo')
      expect { @subject.get(:election_days, nil, nil) }.to raise_error(Oj::ParseError)
    end

    it 'should send the etag if provided' do
      expect_GET('/v2/elections?format=json&apikey=abcdef', 'ghijkl', Net::HTTPOK.new('1.1', '200', 'OK'), '{}')
      expect(@subject.get(:election_days, nil, 'ghijkl')[:data]).to eq('{}')
    end

    it 'should return nil if the etag matches' do
      expect_GET('/v2/elections?format=json&apikey=abcdef', 'ghijkl', Net::HTTPNotModified.new('1.1', '304', 'OK'), 'blah')
      expect(@subject.get(:election_days, nil, 'ghijkl')).to be_nil
    end
  end
end
