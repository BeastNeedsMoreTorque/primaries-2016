We build `ap_id_to_geo_id.tsv` by hand so we can handle subcounties. The method,
vaguely:

1. Download some Associated Press test data for a given race
2. Ensure the race's map is precise to the subunit -- that's in
   `map-builder/index.coffee` and `map-builder/DataFiles.coffee`.
3. Build the cross-reference using the map data and AP data:
   `coffee map-builder/build-geo-id-xref.coffee NH cache/election_day-2016-02-09`
4. Copy/paste stdout (CSV data) into the `ap_id_to_geo_id.tsv`
5. Handle the stderr:
    * Match up every `ap_id` that remains with a `geo_id`, by staring at names
    * Copy every remaining `geo_id` into the spreadsheet, leaving `ap_id` nil

Do this once for each state that includes subcounty data.

Here are the final guarantees you must uphold:

* Every `ap_id` points to a `geo_id`
* Every `geo_id` from every map is in the spreadsheet (maybe without an `ap_id`)
