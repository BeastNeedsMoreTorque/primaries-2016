require_relative '../lib/schedule_methods'

# Describes what the production server actually does.
#
# This is a bit hack-y: we're communicating with the production server via git
# commits. At this phase of development, it seems right.
module ServerSchedule
  extend ScheduleMethods

  # Every TickIntervalInS seconds, we "tick". On a tick, something happens.
  #
  # After the task *finishes*, we start waiting for another tick. So if
  # TickIntervalInS is 1s and have two "pollster" tasks lined up that take
  # 10s, then the two "pollster" tasks will start 11s apart.
  #
  # (If we didn't wait until *after* the task finishes, we could end up
  # bunching API requests together, which could exhaust our quota. Better too
  # few requests than too many, because they're more likely to succeed.)
  TickIntervalInS = 1*60 # every 1min

  # The list of ticks.
  #
  # The first tick happens immediately when the program starts. The next happens
  # TickIntervalInS seconds afterwards. After the last item in the list, we wait
  # TickIntervalInS seconds and start back at the beginning.
  #
  # Possible ticks:
  #
  # * del_super: Get the latest del_super report from AP. 2 API requests.
  # * election_day('YYYY-MM-DD'): Update vote counts from AP. 1 API request.
  # * pollster: Update all polls from Pollster. Takes a few seconds (there are
  #             lots of HTTP requests), but there's no API request limit.
  # * nothing: does nothing.
  #
  # Our limit is 10 API requests per minute.
  Ticks = [
    del_super,
    pollster,
    election_day('2016-05-10'),
    election_day('2016-05-03'),
    election_day('2016-04-26'),
    election_day('2016-04-19'),
    election_day('2016-04-09'),
    election_day('2016-04-05'),
    election_day('2016-03-26'),
    election_day('2016-03-22'),
    election_day('2016-03-15'),
    election_day('2016-03-12'),
    election_day('2016-03-10'),
    election_day('2016-03-08'),
    election_day('2016-03-06'),
    election_day('2016-03-05'),
    election_day('2016-03-01'),
    election_day('2016-02-27'),
    election_day('2016-02-23'),
    election_day('2016-02-20'),
    election_day('2016-02-09'),
    election_day('2016-02-01')
  ]

  # On election night, do something like this:
  #
  #TickIntervalInS = 10
  #
  #Ticks = [
  #  del_super,
  #  election_day('2016-05-10'),
  #  election_day('2016-05-10'),
  #  election_day('2016-05-10'),
  #  election_day('2016-05-10'),
  #  election_day('2016-05-10')
  #]

  #
  # ... that will update votes five times per minute (average once per 12s) and
  # delegate counts once a minute. Total: 7 API requests per minute.
end
