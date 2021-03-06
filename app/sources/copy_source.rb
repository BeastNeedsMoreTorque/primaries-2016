# A Source that comes from ArchieML copy>
#
# The input will be parsed as ArchieML.
#
# Provides:
#
# * raw_data: nested Hash
# * race_days: id, title, body, tweet, pubbed_dt, updated_dt_or_nil
# * races: race_day_id, party_id, state_code, text, over
# * primaries_landing_page_copy (String)
# * primaries_delegates_explainer (String)
class CopySource
  RaceDay = RubyImmutableStruct.new(:id, :title, :body, :tweet, :pubbed_dt, :updated_dt_or_nil)
  Race = RubyImmutableStruct.new(:race_day_id, :party_id, :state_code, :text, :over) do
    attr_reader(:id)

    def after_initialize
      @id = "#{@race_day_id}-#{@party_id}-#{@state_code}"
    end
  end

  attr_reader(:raw_data, :landing_page_copy, :delegates_explainer, :races, :race_days)

  def initialize(archieml_string)
    @raw_data = Archieml.load(archieml_string)
    @primaries_landing_page_copy = @raw_data['primaries']['landing_page_copy']
    @primaries_delegates_explainer = @raw_data['primaries']['delegates_explainer']

    @race_days = @raw_data['primaries']['race-days'].map do |hash|
      RaceDay.new(
        hash['date'],
        hash['title'],
        hash['body'],
        hash['tweet'],
        hash['pubbed_dt'],
        hash['updated_dt'] || nil
      )
    end

    @races = @raw_data['primaries']['races'].map do |hash|
      Race.new(hash['date'], hash['party'], hash['state'], hash['text'], hash['over'] == 'true')
    end
  end
end
