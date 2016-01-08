County = Struct.new(:fips_code) do
  def fips_int; fips_code.to_i; end # Don't worry, Ruby won't parse '01234' as octal
  def id; fips_int; end

  def self.find(id)
    @by_id ||= all.map{ |c| [ c.id, c ] }.to_h
    @by_id.fetch(id)
  end

  def self.all=(v); @all = v; end
  def self.all; @all; end
end
