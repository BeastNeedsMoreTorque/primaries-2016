require_relative './base_view'

require_relative '../models/race_day'

class RaceDayView < BaseView
  attr_reader(:race_day)

  def initialize(database, race_day)
    super(database)
    @race_day = race_day
  end

  def output_path; "2016/primaries/#{race_day.id}.html"; end
  def hed; race_day_copy ? race_day_copy['title'] : nil; end
  def body; race_day_copy ? race_day_copy['body'] : nil; end

  def race_day_states; race_day.states.sort_by(&:name); end

  def race_day_copy
    @race_day_copy ||= copy
      .fetch('primaries', {})
      .fetch('race-days', [])
      .find { |rd| rd['date'] == race_day.id }
  end

  def race_text(race)
    return nil if !race

    @race_text ||= {}
    if !@race_text.include?(race)
      node = copy
        .fetch('primaries', {})
        .fetch('races', [])
        .find { |r| r['state'] == race.state_code && r['party'] == race.party_id }
      @race_text[race] = node && node['text'] || nil
    end
    @race_text[race]
  end

  def self.generate_all(database)
    database.race_days.each do |race_day|
      self.generate_for_view(RaceDayView.new(database, race_day))
    end
  end
end
