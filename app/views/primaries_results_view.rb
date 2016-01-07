require_relative './base_view'

require_relative '../models/candidate'
require_relative '../models/candidate_county'
require_relative '../models/candidate_state'

class PrimariesResultsView < BaseView
  def output_path; "2016/primaries/results.json"; end

  def build_json
    JSON.dump(
      candidate_csv: candidate_csv,
      candidate_state_csv: candidate_state_csv,
      candidate_county_csv: candidate_county_csv
    )
  end

  def candidate_csv
    header = "candidate_id,n_delegates,n_unpledged_delegates\n"
    data = Candidate.all.map{ |c| "#{c.id},#{c.n_delegates},#{c.n_unpledged_delegates}" }.join("\n")
    header + data
  end

  def candidate_state_csv
    header = "candidate_id,state_code,n_votes,n_delegates\n"
    data = CandidateState.all.map{ |cs| "#{cs.candidate_id},#{cs.state_code},#{cs.n_votes},#{cs.n_delegates}" }.join("\n")
    header + data
  end

  def candidate_county_csv
    header = "candidate_id,fips_int,n_votes\n"
    data = CandidateCounty.all.map{ |cc| "#{cc.candidate_id},#{cc.fips_int},#{cc.n_votes}" }.join("\n")
    header + data
  end

  def self.generate_all
    generate_for_view(PrimariesResultsView.new)
  end

  protected

  def self.generate_for_view(view)
    path = "#{Paths.Dist}/#{view.output_path}"
    $logger.debug("Generating #{path}")
    output = view.build_json
    self.write_contents(path, output)
  end
end
