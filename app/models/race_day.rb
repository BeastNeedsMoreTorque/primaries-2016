require 'date'
require 'set'

RaceDay = RubyImmutableStruct.new(:database, :id, :enabled, :title, :body, :tweet, :pubbed_dt, :updated_dt_or_nil) do
  attr_reader(:date)

  # All Races on this day
  attr_reader(:races)

  # States that have one or more races on this day
  attr_reader(:states)

  # Array of [ State, [ [Party, Race_or_nil, other_Races] ] ]
  #
  # Usage:
  #
  #   race_day.state_party_races do |state, party_races|
  #     party_races.each do |party, race_day_race, other_races |
  #       ...
  #     end
  #   end
  attr_reader(:state_party_races)

  attr_reader(
    :candidate_county_races,
    :candidate_race_days,
    :candidate_races,
    :candidate_states,
    :candidate_race_subcounties,
    :county_races,
    :race_subcounties
  )

  def after_initialize
    @date = Date.parse(id)

    @races = database.races
      .select{ |r| r.race_day_id == id }
      .sort_by! { |r| "#{r.state_name} #{r.party_name}" }

    @states = races.map(&:state).uniq.sort_by(&:name)

    @state_party_races = states.map do |state|
      [
        state,
        database.parties.map do |party|
          [
            party,
            database.races.find("#{@id}-#{party.id}-#{state.code}"),
            database.races.find_all_by_party_state_id("#{party.id}-#{state.code}")
              .reject { |r| r.race_day_id == id }
          ]
        end
      ]
    end

    @candidate_races = @races.flat_map(&:candidate_races)
    @candidate_states = @races.flat_map(&:candidate_states)
    @candidate_county_races = @races.flat_map(&:candidate_county_races)
    @candidate_race_subcounties = @races.flat_map(&:candidate_race_subcounties)
    @county_races = @races.flat_map(&:county_races)
    @race_subcounties = @races.flat_map(&:race_subcounties)
  end

  def party_race_days
    database.party_race_days.find_all_by_race_day_id(id)
  end

  def disabled?; !@enabled; end
  def enabled?; @enabled; end

  def today?
    database.now.to_datetime.new_offset('Eastern').to_date.to_s == id
  end

  # "past" when all races have finished reporting
  # "present" if any race is reporting
  # "future" if no races are reporting
  def when_race_day_happens
    tenses = races.map(&:when_race_happens)

    if tenses.all? { |t| t == 'past' }
      'past'
    elsif tenses.all? { |t| t == 'future' }
      'future'
    else
      # If there's one past and one future, the race_day is 'present'
      'present'
    end
  end

  def present?; when_race_day_happens == 'present'; end
  def past?; when_race_day_happens == 'past'; end
  def future?; when_race_day_happens == 'future'; end

  def title
    if @title
      @title
    elsif @races.length == 1
      @races.first.title
    else
      raise "Need title for #{self.inspect}"
    end
  end

  def href
    "/2016/primaries/#{id}"
  end
end
