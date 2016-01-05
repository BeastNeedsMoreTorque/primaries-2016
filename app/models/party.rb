class Party
  attr_reader(:id, :name, :adjective)

  def initialize(id, name, adjective)
    @id = id
    @name = name
    @adjective = adjective
  end

  def candidates
    Candidate.all.select { |c| c.party == self }
  end

  def self.all
    @all ||= [
      Party.new(:Dem, 'Democrats', 'Democratic'),
      Party.new(:GOP, 'Republicans', 'Republican')
    ]
  end

  def self.find_by_id(id)
    @by_id ||= all.map{ |p| [ p.id, p ] }.to_h
    @by_id.fetch(id.to_sym)
  end
end
