require_relative './source'

require_relative '../../lib/sparkline'

# Pollster national polls: one for Democrats, one for Republicans
#
# Provides:
#
# * candidates: last_name, poll_percent, sparkline, poll_last_update
# * candidate_states: last_name, state_code, poll_percent, sparkline
# * party_states: party_id, state_code, slug, last_updated
class PollsterSource < Source
  Candidate = RubyImmutableStruct.new(:last_name, :poll_percent, :sparkline, :last_updated)
  CandidateState = RubyImmutableStruct.new(:last_name, :state_code, :poll_percent, :sparkline)

  PartyState = RubyImmutableStruct.new(:party_id, :state_code, :slug, :last_updated) do
    attr_reader(:id)

    def after_initialize
      @id = "#{@party_id}-#{@state_code}"
    end
  end

  attr_reader(:candidates, :candidate_states, :party_states)

  def initialize(pollster_jsons)
    @candidates = []
    @candidate_states = []
    @party_states = []

    for pollster_json in pollster_jsons
      state_code = pollster_json[:state]

      if state_code == 'US'
        @candidates += parse_national_poll(pollster_json)
      else
        @candidate_states += parse_state_poll(state_code, pollster_json)
        @party_states << parse_party_state(state_code, pollster_json)
      end
    end
  end

  private

  def parse_national_poll(json)
    last_updated = DateTime.parse(json[:last_updated])
    last_day = sparkline_last_day(json[:election_date])

    ret = []
    choice_to_sparkline = {}

    for estimate in json[:estimates]
      choice = estimate[:choice] # Usually last_name, but sometimes not (e.g., "Rand Paul")
      last_name = estimate[:last_name]
      poll_percent = estimate[:value]

      sparkline = Sparkline.new(last_day.mjd)

      ret << Candidate.new(last_name, poll_percent, sparkline, last_updated)
      choice_to_sparkline[choice] = sparkline
    end

    fill_sparklines(choice_to_sparkline, json[:estimates_by_date])

    ret
  end

  def parse_state_poll(state_code, json)
    last_day = sparkline_last_day(json[:election_date])

    ret = []
    choice_to_sparkline = {}

    for estimate in json[:estimates]
      choice = estimate[:choice] # Usually last_name, but sometimes not (e.g., "Rand Paul")
      last_name = estimate[:last_name]
      poll_percent = estimate[:value]

      sparkline = Sparkline.new(last_day.mjd)

      ret << CandidateState.new(last_name, state_code, poll_percent, sparkline)
      choice_to_sparkline[choice] = sparkline
    end

    fill_sparklines(choice_to_sparkline, json[:estimates_by_date])

    ret
  end

  def parse_party_state(state_code, json)
    party_id = json[:slug] =~ /-democratic-/ ? 'Dem' : 'GOP'
    last_updated = DateTime.parse(json[:last_updated])
    slug = json[:slug]

    PartyState.new(party_id, state_code, slug, last_updated)
  end

  def fill_sparklines(choice_to_sparkline, estimates_by_date)
    for estimate_points in estimates_by_date
      date_mjd = Date.parse(estimate_points[:date]).mjd

      for estimate in estimate_points[:estimates]
        choice = estimate[:choice]
        value = estimate[:value]

        sparkline = choice_to_sparkline[choice]
        if sparkline # "Lessig" might show up in :estimates_by_date but not :estimates
          sparkline.add_value(date_mjd, value)
        end
      end
    end
  end

  def sparkline_last_day(json_election_date_or_nil)
    if json_election_date_or_nil
      [ Date.today, Date.parse(json_election_date_or_nil) ].min
    else
      Date.today
    end
  end
end
