require_relative './source'

# Pollster national polls: one for Democrats, one for Republicans
#
# Provides:
#
# * candidates: name (sometimes last, sometimes full), poll_percent, sparkline, poll_last_update
# * candidate_states: name (sometimes last, sometimes full), state_code, poll_percent, sparkline, poll_last_update
class PollsterNationalSource < Source
  Candidate = RubyImmutableClass.new(:name, :poll_percent, :sparkline, :last_updated)
  CandidateState = RubyImmutableClass.new(:name, :state_code, :poll_percent, :sparkline, :last_updated)

  def initialize(dem_jsons, gop_jsons)
    choice_to_candidate = {}

    @candidate_states = []
    @races = []

    [ [ 'Dem', dem_jsons ], [ 'GOP', gop_jsons ] ].each do |party_id, jsons|
      for chart_data in jsons
        state_code = chart_data[:state]
        last_updated = chart_data[:last_updated]

        last_day = if chart_data[:election_date]
          [ Date.today, Date.parse(chart_data[:election_date]) ].min
        else
          Date.today
        end

        for estimate_points in chart_data[:estimates_by_date]
          date = Date.parse(estimate_points[:date])

          for estimate in estimate_points[:estimates]
            choice = estimate[:choice]
          end
        end
      end
    end
  end
end
