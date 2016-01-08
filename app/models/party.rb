require_relative './candidate'

Party = Struct.new(:id, :name, :adjective) do
  def candidates
    @candidates ||= Candidate.all.select { |c| c.party == self }
  end

  def self.all
    @all ||= [
      Party.new(:Dem, 'Democrats', 'Democratic'),
      Party.new(:GOP, 'Republicans', 'Republican')
    ]
  end

  def self.find(id)
    @by_id ||= all.map{ |p| [ p.id, p ] }.to_h
    @by_id.fetch(id.to_sym)
  end
end
