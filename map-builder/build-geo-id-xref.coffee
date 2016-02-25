# Outputs a CSV file that maps AP "reportingunitID" to Census Bureau "GEOID".
#
# Usage:
#   build-geo-id-xref.coffee NH ../cache/election-2016-02-09

fs = require('fs')
geo_loader = require('./geo-loader')

compare_rows = (a, b) -> a.fips_int - b.fips_int || a.name.localeCompare(b.name)

load_geo_rows = (state_code, callback) ->
  geo_loader.load_features state_code, (err, features) ->
    return callback(err) if err

    geo_rows = for feature in features
      props = feature.properties
      fips_int: +"#{props.STATEFP}#{props.COUNTYFP}"
      geo_id: +props.GEOID
      name: props.NAME

    geo_rows.sort(compare_rows)

    callback(null, geo_rows)

load_ap_rows = (state_code, filename, callback) ->
  fs.readFile filename, (err, data) ->
    return callback(err) if err

    ap_id_to_row = {} # ap_id -> { fips_int, ap_id, name }

    obj = JSON.parse(data)
    for race in obj.races
      for reportingUnit in race.reportingUnits when reportingUnit.level == 'subunit' && reportingUnit.statePostal == state_code
        ap_id_to_row[reportingUnit.reportingunitID] =
          ap_id: +reportingUnit.reportingunitID
          fips_int: +reportingUnit.fipsCode
          name: reportingUnit.reportingunitName

    ap_rows = (row for __, row of ap_id_to_row)
    ap_rows.sort(compare_rows)

    callback(null, ap_rows)

merge_rows = (ap_rows, geo_rows) ->
  i = j = 0

  merged = []
  ap_only = []
  geo_only = []

  while i < ap_rows.length || j < geo_rows.length
    if i == ap_rows.length
      geo_only.push(geo_rows[j])
      j += 1
    else if j == geo_rows.length
      ap_only.push(ap_rows[i])
      i += 1
    else
      ap_row = ap_rows[i]
      geo_row = geo_rows[j]

      d = compare_rows(ap_row, geo_row)
      if d < 0
        ap_only.push(ap_row)
        i += 1
      else if d > 0
        geo_only.push(geo_row)
        j += 1
      else
        merged.push
          fips_int: ap_row.fips_int
          name: ap_row.name
          ap_id: ap_row.ap_id
          geo_id: geo_row.geo_id
        i += 1
        j += 1

  [ merged, ap_only, geo_only ]

if process.argv.length != 4
  console.warn("Usage: #{process.argv[0]} #{process.argv[1]} state_code ap_response_for_that_state.json")
  process.exit(1)

load_geo_rows process.argv[2], (err, geo_rows) ->
  throw err if err

  load_ap_rows process.argv[2], process.argv[3], (err, ap_rows) ->
    throw err if err

    [ rows, ap_only_rows, geo_only_rows ] = merge_rows(ap_rows, geo_rows)

    process.stdout.write('ap_id\tgeo_id\n')

    for row in rows
      process.stdout.write("#{row.ap_id}\t#{row.geo_id}\n")

    if ap_only_rows.length
      process.stderr.write('\nCould not match these Associated Press reporting units:\n\n')
      process.stderr.write(ap_only_rows.map((x) -> JSON.stringify(x)).join('\n') + '\n')

    if geo_only_rows.length
      process.stderr.write('\nCould not match these Census Bureau reporting units:\n\n')
      process.stderr.write(geo_only_rows.map((x) -> JSON.stringify(x)).join('\n') + '\n')
