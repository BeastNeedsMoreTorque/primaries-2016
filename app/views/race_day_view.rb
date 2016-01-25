require_relative './base_view'

require_relative '../models/race_day'

class RaceDayView < BaseView
  attr_reader(:race_day)

  def initialize(database, race_day)
    super(database)
    @race_day = race_day
  end

  def output_path; "2016/primaries/#{race_day.id}.html"; end
  def page_title; "2016 Presidential Primaries: #{race_day.date.strftime('%B %-d, %Y')}"; end
  def layout; 'main'; end
  def stylesheets; [ asset_path('main.css') ]; end

  def hed; race_day_copy ? race_day_copy['title'] : nil; end
  def race_date; "#{race_day.date.strftime('%B %-d, %Y')}"; end
  def body; race_day_copy ? race_day_copy['body'] : nil; end
  def pubbed_dt; race_day_copy ? race_day_copy['pubbed'] : nil; end
  def updated_dt; race_day_copy ? race_day_copy['updated'] : nil; end

  # The race day prior to the one we're focused on
  def previous_race_day
    database.race_days
      .select { |rd| rd.id < race_day.id }
      .last
  end

  # The race day immediately after the one we're focused on
  def next_race_day
    database.race_days
      .select { |rd| rd.id > race_day.id }
      .first
  end

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
    database.race_days.select(&:enabled?).each do |race_day|
      self.generate_for_view(RaceDayView.new(database, race_day))
    end
  end
end
