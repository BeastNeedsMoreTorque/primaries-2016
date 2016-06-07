#!/usr/bin/env ruby
#
# Writes CSV data to stdout. We'll use this to calculate how candidates did and
# when they dropped out.

ENV['AP_API_KEY']='1'
require_relative '../lib/env'
require_relative '../app/models/database'

def slugify(s)
  s.downcase.gsub(/[^-a-z0-9]+/, '-')
end

def dump_candidates
  source = Database.default_sheets_source

  puts 'year,party,candidate,dropout_date'
  puts source.candidates
    .map { |c| [ 2016, c.party_id, slugify(c.last_name), c.dropped_out_date_or_nil.to_s ].join(',') }
    .join("\n")
end

# For election-2012:
#
#     Primary.all.each do |p|
#       total = p.election_results.statewide.map(&:vote_count).sum
#       p.election_results.statewide.each do |er|
#         puts [ 2012, 'GOP', p.state_postal, p.primary_date, er.person.last_name.downcase.gsub(/[^-a-z0-9]+/, '-'), er.vote_count, total ].join(',')
#       end
#     end
def dump_candidate_races
  source = Database.default_ap_election_days_source

  id_to_candidate_slug = Database.default_sheets_source
    .candidates
    .reduce({}) { |h, c| h[c.id] = slugify(c.last_name); h }

  id_to_race = source.races
    .reduce({}) { |h, r| h[r.id] = r; h }

  puts 'year,party,state_code,date,candidate,n_votes,race_n_votes'
  source.candidate_races.each do |cr|
    candidate_id, race_id = cr.id.split(/-/, 2)
    candidate_slug = id_to_candidate_slug[candidate_id] || '?'
    race = id_to_race[race_id]

    puts [ 2016, race.party_id, race.state_code, race.id[0...10], candidate_slug, cr.n_votes, race.n_votes ].join(',')
  end
end

dump_candidates
puts
dump_candidate_races
