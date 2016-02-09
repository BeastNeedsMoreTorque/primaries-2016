require_relative '../app/models/race_day'

module PrimariesEmbedView
  def leading_democrat
    parties.find!(:Dem).candidates.max_by(&:n_delegates)
  end

  def leading_republican
    parties.find!(:GOP).candidates.max_by(&:n_delegates)
  end
end
