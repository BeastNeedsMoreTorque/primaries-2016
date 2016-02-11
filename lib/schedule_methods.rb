# These "ticks" are used in config/schedule.rb
module ScheduleMethods
  # Tick that asks for the del_super report from AP.
  #
  # Costs 2 API requests (limit 10/min).
  def del_super; Tick::DelSuper.new; end

  # Tick that asks for results from a single election day.
  #
  # Costs 1 API request (limit 10/min).
  def election_day(date_s); Tick::ElectionDay.new(date_s); end

  # Tick that refreshes poll averages from Pollster.
  #
  # There's no API-request limit; but Pollster polling takes a few seconds, so
  # we should do this relatively rarely.
  def pollster; Tick::Pollster.new; end

  # Tick that does nothing.
  #
  # This is useful when we want the server to use very few API requests, so we
  # can use the API requests on our dev machines.
  def nothing; Tick::Nil.new; end

  module Tick
    class DelSuper; end
    class Nil; end
    class Pollster; end

    class ElectionDay
      attr_reader(:date_s)
      def initialize(date_s); @date_s = date_s; end
    end
  end
end
