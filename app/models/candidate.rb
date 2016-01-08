require_relative './party'

# A person who wants to be president
Candidate = Struct.new(:id, :party_id, :name, :n_delegates, :n_unpledged_delegates) do
  def party; Party.find(party_id); end

  def self.include?(id)
    by_id.include?(id.to_s)
  end

  def self.find(id)
    by_id.fetch(id.to_s)
  end

  def self.all=(v); @all = v; end
  def self.all; @all; end

  private

  def self.by_id
    @by_id ||= all.map{ |c| [ c.id, c ] }.to_h
  end
end
