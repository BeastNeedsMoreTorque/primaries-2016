require_relative './collection_class'
require_relative '../models/race_day'

RaceDays = CollectionClass.new('race_days', 'race_day', RaceDay)
