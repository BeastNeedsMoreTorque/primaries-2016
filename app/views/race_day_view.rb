require_relative './base_view'

require_relative '../helpers/dot_group_helper'
require_relative '../models/race_day'

class RaceDayView < BaseView
  include DotGroupHelper

  attr_reader(:race_day)

  def initialize(database, race_day)
    super(database)
    @race_day = race_day
  end

  def output_path; "2016/primaries/#{race_day.id}.html"; end
  def page_title; "2016 Presidential Primaries: #{race_day.date.strftime('%B %-d, %Y')}"; end
  def layout; 'main'; end
  def body_class; super + ' show-delegates'; end
  def stylesheets; [ asset_path('main.css') ]; end

  def hed; race_day.title; end
  def body; race_day.body; end
  def social_img; absolute_image_path_if_possible('share.png'); end
  def twitter; race_day.tweet; end
  def pubbed_dt; race_day.pubbed_dt; end
  def updated_dt; race_day.updated_dt_or_nil; end

  def meta
    @meta ||= {
      page_title: "HuffPost 2016 Election Coverage: #{hed}",
      page_description: "#{body}",
      author: "HuffPostPolitics",
      author_twitter: "HuffPostPol",
      social_image_url: "#{social_img}",
      twitter_desc: "#{twitter}"
    }
  end

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

  def self.generate_all(database)
    database.race_days.select(&:enabled?).each do |race_day|
      self.generate_for_view(RaceDayView.new(database, race_day))
    end
  end
end
