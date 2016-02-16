require_relative '../app/models/race_day'

module PrimariesWidgetsView
  def race_day; @race_day ||= database.race_days.find('2016-02-09'); end
end
