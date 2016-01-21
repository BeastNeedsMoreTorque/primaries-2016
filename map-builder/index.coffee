d3 = require('d3')
fs = require('fs')
get = require('simple-get')
tar = require('tar-fs')
zlib = require('zlib')
shapefile = require('shapefile')
topojson = require('topojson')

require('d3-geo-projection')(d3)

MaxWidth = 350
MaxHeight = 350

DataFiles =
  cities:
    basename: 'citiesx010g'
    url: 'http://dds.cr.usgs.gov/pub/data/nationalatlas/citiesx010g_shp_nt00962.tar.gz'
    shp_size: 1069308
  counties:
    basename: 'countyp010g'
    url: 'http://dds.cr.usgs.gov/pub/data/nationalatlas/countyp010g.shp_nt00934.tar.gz'
    shp_size: 48737664

is_data_downloaded = (key, callback) ->
  data_file = DataFiles[key]
  shp_size = data_file.shp_size
  path = "./input/#{data_file.basename}.shp"

  fs.stat path, (err, stats) ->
    ret = if err
      if err.errno == 'ENOENT'
        throw err
      else
        false
    else
      stats.size == shp_size

    callback(null, ret)

download_data = (key, callback) ->
  data_file = DataFiles[key]
  basename = data_file.basename
  url = data_file.url

  console.log("GET #{url}...")
  get url, (err, res) ->
    throw err if err

    res
      .pipe(zlib.createGunzip())
      .pipe(tar.extract('./input'))
      .on('error', (err) -> throw err)
      .on('finish', -> callback())

ensure_data_downloaded = (key, callback) ->
  is_data_downloaded key, (err, is_downloaded) ->
    throw err if err

    if is_downloaded
      callback(null)
    else
      download_data(key, callback)

load_features = (key, callback) ->
  console.log("Loading #{key}...")
  ensure_data_downloaded key, (err) ->
    data_file = DataFiles[key]
    basename = data_file.basename
    shp_filename = "./input/#{basename}.shp"
    shapefile.read shp_filename, (err, feature_collection) ->
      throw err if err
      callback(null, feature_collection.features)

features_by_state = {} # { state_code -> { cities: [...], counties: [...] } }

organize_features = (key, features) ->
  console.log("Organizing #{key} by state...")
  for feature in features
    state_code = feature.properties.STATE
    if state_code not of features_by_state
      features_by_state[state_code] = { cities: [], counties: [] }
    features_by_state[state_code][key].push(feature)

calculate_projection_width_height = (features) ->
  feature_collection = { type: 'FeatureCollection', features: features.counties }

  # Calculate projection parameters...

  alaska_safe_projection = (arr) -> [ (if arr[0] > 172 then -360 + arr[0] else arr[0]), arr[1] ]
  path1 = d3.geo.path().projection(alaska_safe_projection)
  ll_bounds = path1.bounds(feature_collection)

  lon = (ll_bounds[0][0] + ll_bounds[1][0]) / 2
  lat = (ll_bounds[0][1] + ll_bounds[1][1]) / 2
  # parallels at 1/6 and 5/6: http://www.georeference.org/doc/albers_conical_equal_area.htm
  lats = [
    ll_bounds[0][1] + 5 / 6 * (ll_bounds[1][1] - ll_bounds[0][1]),
    ll_bounds[0][1] + 1 / 6 * (ll_bounds[1][1] - ll_bounds[0][1])
  ]

  projection = d3.geo.albers()
    .rotate([ -lon, 0 ])
    .center([ 0, lat ])
    .parallels(lats)
    .scale(1)
    .translate([0, 0])

  # Scale to fill the center of the SVG
  # http://stackoverflow.com/questions/14492284/center-a-map-in-d3-given-a-geojson-object
  path2 = d3.geo.path().projection(projection)
  b = path2.bounds(feature_collection)

  width = MaxWidth
  height = MaxHeight
  aspect_ratio = (b[1][0] - b[0][0]) / (b[1][1] - b[0][1])
  if aspect_ratio > 1
    height = Math.ceil(width / aspect_ratio)
  else
    width = Math.ceil(height * aspect_ratio)

  s = 0.95 / Math.max((b[1][0] - b[0][0]) / width, (b[1][1] - b[0][1]) / height)
  t = [(width - s * (b[1][0] + b[0][0])) / 2, (height - s * (b[1][1] + b[0][1])) / 2]

  projection.scale(s).translate(t)

  [ projection, width, height ]

project_features = (features, projection) ->
  for key in Object.keys(features)
    features[key] = d3.geo.project({ type: 'FeatureCollection', features: features[key] }, projection)
  features

topojsonize = (features) ->
  # Modeled after topojson's bin/topojson
  options =
    'pre-quantization': 2000
    'post-quantization': 2000
    'coordinate-system': 'cartesian'
    'minimum-area': 5
    'preserve-attached': false
    'property-transform': (d) ->
      p = d.properties
      state_code: p.STATE
      fips_string: p.ADMIN_FIPS # counties only
      name: p.ADMIN_NAME || p.NAME
      feature: p.FEATURE # cities only; we filter for 'Civil'
      population: +p.POP_2010 # cities only

  topology = topojson.topology(features, options)
  topojson.clockwise(topology, options)
  topojson.simplify(topology, options)
  topojson.filter(topology, options)
  topology

compress_svg_path = (path) ->
  # First, round to one decimal and multiply by 10
  path = path.replace(/\.(\d)\d+/g, (__, one_decimal) -> one_decimal)

  # Now, convert absolute coordinates to relative ones.
  throw 'Unexpected character in path' if /[^MLZ,\.0-9]/.test(path)

  rings = path.split(/Z/g).filter((s) -> s.length > 0) # Each ring ends with "Z"

  compressed_rings = rings.map (ring) ->
    throw 'Ring did not start with "M"' if ring[0] != 'M'

    point_strings = ring.slice(1).split(/L/g) # "1,2" pairs

    parse_point_string = (s) -> s.split(',').map((x) -> +x)

    point = parse_point_string(point_strings.shift())

    commands = [ "M#{point[0]},#{point[1]}" ]

    next_instr = 'l'
    for point_string in point_strings
      point2 = parse_point_string(point_string)

      continue if point[0] == point2[0] && point[1] == point2[1]

      commands.push("#{next_instr}#{point2[0] - point[0]},#{point2[1] - point[1]}")

      point = point2
      next_instr = ' ' # Makes output easier to read

    commands.push('Z')

    commands.join('')

  compressed_rings.join('')

render_state = (state_code, features, callback) ->
  output_filename = "./output/#{state_code}.svg"

  if (features.counties.length == 0)
    console.log("Skipping #{output_filename} because we have no county paths")
    return callback(null)

  console.log("Rendering #{output_filename}...")

  [ projection, width, height ] = calculate_projection_width_height(features)
  features = project_features(features, projection)
  path = d3.geo.path().projection(null)
  topology = topojsonize(features)

  # Note that our viewBox is width/height multiplied by 10. We round everything to integers to compress
  data = [
    '<?xml version="1.0" encoding="utf-8"?>'
    '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">'
    "<svg version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\" width=\"#{width}\" height=\"#{height}\" viewBox=\"0 0 #{width} #{height}\">"
    "  <defs>"
    "    <pattern id=\"pattern-no-results\" width=\"50\" height=\"50\" patternUnits=\"userSpaceOnUse\">"
    "      <rect width=\"50\" height=\"50\" fill=\"#ddd\"/>"
    "      <path d=\"M-5,5L5,-5M-5,55L55,-5M45,55L55,45\" stroke-width=\"10\" stroke=\"#666666\"/>"
    "    </pattern>"
    "  </defs>"
  ]

  data.push('  <g class="counties" transform="scale(0.1)">')
  for geometry in topology.objects.counties.geometries
    # Minnesota has a weird FIPS code, 27000, for Lake Superior
    continue if /000$/.test(geometry.properties.fips_string)
    d = path(topojson.feature(topology, geometry))
    d = compress_svg_path(d)
    data.push("    <path data-fips-int=\"#{+geometry.properties.fips_string}\" data-name=\"#{geometry.properties.name}\" d=\"#{d}\"/>")
  data.push('  </g>')

  data.push('  <g class="cities">')
  cities = (topojson.feature(topology, geometry) for geometry in topology.objects.cities.geometries)
    .sort (a, b) ->
      # Prefer "Civil" to "Populated Place". Some states (e.g., VI) don't have
      # any cities, so we can't filter.
      p1 = a.properties
      p2 = b.properties
      ((p1 == 'Civil' && -1 || 0) - (p2 == 'Civil' && -1 || 0)) || p2.population - p1.population || p1.name.localeCompare(p2.name)
    .slice(0, 3)
  for city in cities
    p = city.geometry.coordinates
    x = p[0].toFixed(1)
    y = p[1].toFixed(1)
    data.push("    <circle r=\"3\" cx=\"#{x}\" cy=\"#{y}\"/>")
    data.push("    <text x=\"#{x}\" y=\"#{y}\">#{city.properties.name}</text>")
  data.push('  </g>')

  data.push('</svg>')

  data_string = data.join('\n')
  fs.writeFile(output_filename, data_string, callback)

render_all_states = (callback) ->
  pending_states = Object.keys(features_by_state).sort()

  step = (next) ->
    if pending_states.length > 0
      state_code = pending_states.shift()
      render_state state_code, features_by_state[state_code], (err) ->
        throw err if err
        process.nextTick(-> step(next))
    else
      next(null)

  step(callback)

load_features 'cities', (err, city_features) ->
  throw err if err
  organize_features('cities', city_features)
  load_features 'counties', (err, county_features) ->
    throw err if err
    organize_features('counties', county_features)

    render_all_states (err) ->
      throw err if err
      console.log('Done! Now try `cp output/*.svg ../assets/maps/states/`')
