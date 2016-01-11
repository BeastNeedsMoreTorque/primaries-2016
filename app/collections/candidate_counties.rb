require_relative './collection_class'
require_relative '../models/candidate_county'

CandidateCounties = CollectionClass.new('candidate_counties', 'candidate_county', CandidateCounty)
