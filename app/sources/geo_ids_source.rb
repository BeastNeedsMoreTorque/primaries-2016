# Data about Associated Press IDs
#
# Provides:
#
# * geo_ids: Hash from ap_id (Integer) to geo_id (Integer)
# * ap_ids: Hash from geo_id (Integer) to ap_id (Integer)
class GeoIdsSource
  attr_reader(:ap_ids, :geo_ids)

  def initialize
    @ap_ids = {}
    @geo_ids = {}

    for line in IO.read(File.expand_path('../ap_id_to_geo_id.tsv', __FILE__)).split(/\r?\n/)[1..-1]
      next if !line
      ap_id_s, geo_id_s = line.split(/\t/)

      geo_id = geo_id_s.to_i
      ap_id = ap_id_s ? ap_id_s.to_i : nil

      puts line
      puts [ ap_id_s, geo_id_s ].inspect
      puts [ geo_id, ap_id ].inspect

      @ap_ids[geo_id] = ap_id
      @geo_ids[ap_id] = geo_id if ap_id
    end
  end
end
