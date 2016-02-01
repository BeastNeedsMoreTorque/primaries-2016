# A set of data about things.
#
# We create our One Main Database from multiple sources. Each has partial
# information about the world. We make all of them massage their data into
# the format in our `models` directory.
#
# Since each Source only provides partial information, nil values are totally
# allowed: both nil values within models (e.g., `race.ap_id` may be nil if AP
# does not have data for a certain race), and nil collections (e.g., `today`
# may be nil in the AP data source). Think of this class as a recommendation.
#
# At the end of the day, something will merge these Sources together.
class Source
  attr_reader(:counties)
  attr_reader(:parties)
  attr_reader(:candidates)
  attr_reader(:states)
  attr_reader(:candidate_counties)
  attr_reader(:candidate_states)
  attr_reader(:county_parties)
  attr_reader(:races)
  attr_reader(:race_days)

  # The last Date we'll render
  attr_reader(:last_date)

  # Today's Date
  attr_reader(:today)
end
