require_relative './base_view'

require_relative '../models/candidate'
require_relative '../models/candidate_county'
require_relative '../models/candidate_state'
require_relative '../models/county_party'
require_relative '../models/race'

class PrimariesResultsView < BaseView
  def output_path; "2016/primaries/results.json"; end

  def build_json
    JSON.dump(
      candidate_csv: candidate_csv,
      candidate_state_csv: candidate_state_csv,
      candidate_county_csv: candidate_county_csv,
      county_party_csv: county_party_csv,
      race_csv: race_csv
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

  def county_party_csv
    header = "fips_int,party_id,n_precincts_reporting,n_precincts_total,last_updated\n"
    data = CountyParty.all.map{ |cp| "#{cp.fips_int},#{cp.party_id},#{cp.n_precincts_reporting},#{cp.n_precincts_total},#{cp.last_updated}" }.join("\n")
    header + data
  end

  def race_csv
    header = "party_id,state_code,n_precincts_reporting,n_precincts_total,last_updated\n"
    data = Race.all.map{ |r| "#{r.party_id},#{r.state_code},#{r.n_precincts_reporting},#{r.n_precincts_total},#{r.last_updated}" }.join("\n")
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
