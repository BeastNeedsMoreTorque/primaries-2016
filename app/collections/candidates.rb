require_relative './collection_class'
require_relative '../models/candidate'

Candidates = CollectionClass.new('candidates', 'candidate', Candidate)
