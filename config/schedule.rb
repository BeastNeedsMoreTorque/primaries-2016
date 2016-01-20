# Configure the production server.
#
# Every `TimeoutInS` seconds, the server will poll for:
#
# * Delegate counts (two AP API requests), if `RefreshDelegates` is true
# * Race-day results (one AP API request per race day), one for each
#   `YYYY-MM-DD`-format String in the `RefreshPrimariesRaceDays` Array
# * Pollster results (two Pollster API requests) if `RefreshPollsterPrimaries`
#   is true
#
# This is a bit hack-y: we're communicating with the production server via git
# commits. At this phase of development, it seems right.
module ServerSchedule
  TimeoutInS = 300
  RefreshDelegates = true
  RefreshPrimariesRaceDays = [ '2016-02-01' ]
  RefreshPollsterPrimaries = true
end
