d3 = require('d3')
fs = require('fs')
topojson = require('topojson')

require('d3-geo-projection')(d3)

MaxWidth = 350
MaxHeight = 350

geo_loader = require('./geo-loader')

# These cities didn't come from any one source. Adam Hooper compiled them from
# Google searches.
TerritoryCities =
  # American Samoa looks like this:
  #
  #    .
  #
  #
  #
  #
  #
  #    *         ...
  #
  # ... since it's mostly empty (ocean), it looks best if we draw one city per
  # land mass.
  AS: [
    {
      # http://www.geonames.org/AS/largest-cities-in-american-samoa.html
      name: 'Pago Pago'
      latitude: -14.278
      longitude: -170.702
      population: 11500
    }
    {
      # https://en.wikipedia.org/wiki/Taulaga -- it's the only village on the island
      name: 'Taulaga'
      latitude: -11.055
      longitude: -171.088
      population: 35
    }
    {
      # https://en.wikipedia.org/wiki/Fitiuta,_American_Samoa -- it has an airport
      name: 'Fitiuta'
      latitude: -14.222222
      longitude: -169.423611
      population: 358
    }
  ]
  # http://www.geonames.org/GU/largest-cities-in-guam.html
  GU: [
    {
      name: 'Dededo'
      latitude: 13.518
      longitude: 144.839
    }
    {
      name: 'Yigo'
      latitude: 13.536
      longitude: 144.889
    }
    {
      name: 'Tamuning-Tumon-Harmon'
      latitude: 13.488
      longitude: 144.781
    }
  ]
  # http://www.geonames.org/MP/largest-cities-in-northern-mariana-islands.html
  MP: [
    {
      name: 'Saipan'
      latitude: 15.212
      longitude: 145.754
    }
    {
      name: 'San Jose'
      latitude: 14.968
      longitude: 145.62
    }
    {
      name: 'Carolinas Heights'
      latitude: 14.967
      longitude: 145.649
    }
  ]

TerritoryFipsCodeNames =
  # AS: http://www.nws.noaa.gov/mirs/public/prods/maps/map_images/state-maps/cnty_fips/pacific_region/samoa_cnty.pdf
  60040: 'Swains Island'
  60050: 'Western Samoa'
  60010: 'Eastern Samoa'
  60020: "Manu'a"
  60030: 'Rose Island'
  # GU, NM: http://www.nws.noaa.gov/mirs/public/prods/maps/cnty_fips_pr_guam.htm
  66010: 'Guam'
  69085: 'Northern Islands'
  69120: 'Tinian'
  69110: 'Saipan'
  69100: 'Rota'

features_by_state = {} # { state_code -> { cities: [...], counties: [...], subcounties: [...] } }

organize_features = (key, features) ->
  console.log("Organizing #{key} by state...")
  for feature in features
    state_code = feature.properties.STATE
    if state_code not of features_by_state
      features_by_state[state_code] = { cities: [], counties: [], subcounties: [] }
    features_by_state[state_code][key].push(feature)

organize_subcounty_features = (state_code, features) ->
  console.log("Organizing #{state_code} subcounties...")
  for feature in features
    features_by_state[state_code].subcounties.push(feature)

organize_territory_features = (state_code, features) ->
  # Our geo-data for territories (*not* countyp10g) is by county, but counties
  # aren't FIPS codes here. We'll group all the counties by FIPS code and make
  # one big name for them.
  console.log("Organizing #{state_code} features...")

  features_by_state[state_code] = { cities: [], counties: [], subcounties: [] }

  fips_string_to_out_feature = {}

  for in_feature in features
    fips_string = in_feature.properties.GEOID[0 ... 5]

    out_feature = fips_string_to_out_feature[fips_string]
    if !out_feature
      out_feature = fips_string_to_out_feature[fips_string] =
        type: 'Feature'
        properties:
          STATE: state_code
          ADMIN_FIPS: fips_string
          NAME: TerritoryFipsCodeNames[fips_string]
        geometry:
          type: 'MultiPolygon'
          coordinates: []
      features_by_state[state_code].counties.push(out_feature)

    if in_feature.geometry.type == 'MultiPolygon'
      out_feature.geometry.coordinates.splice(Infinity, in_feature.geometry.coordinates)
    else if in_feature.geometry.type == 'Polygon'
      out_feature.geometry.coordinates.push(in_feature.geometry.coordinates)
    else
      throw "Unhandled geometry type: #{in_feature.geometry.type}"

  out_cities = features_by_state[state_code].cities
  for city in TerritoryCities[state_code]
    out_cities.push
      type: 'Feature'
      properties:
        NAME: city.name
        FEATURE: 'Civil'
        POP_2010: 1 # doesn't matter
      geometry:
        type: 'Point'
        coordinates: [ city.longitude, city.latitude ]

  undefined

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
      geoid: p.GEOID # subcounties only
      name: p.ADMIN_NAME || p.NAME
      feature: p.FEATURE # cities only; we filter for 'Civil'
      population: +p.POP_2010 # cities only

  topology = topojson.topology(features, options)
  topojson.clockwise(topology, options)

  geometries = topology.objects.counties.geometries
  topology.objects.counties.geometries = for geometry in geometries
    geometry2 = topojson.mergeArcs(topology, [geometry])
    geometry2.properties = geometry.properties
    geometry2

  topojson.simplify(topology, options)
  topojson.filter(topology, options)
  topojson.prune(topology, options)
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

    # We'll try to put " " instead of "l" for lineto, to make the path easier
    # to read.
    last_instruction_was_l = false

    for point_string in point_strings
      point2 = parse_point_string(point_string)

      dx = point2[0] - point[0]
      dy = point2[1] - point[1]

      continue if dx == 0 && dy == 0

      if dx == 0
        commands.push("v#{dy}")
        last_instruction_was_l = false
      else if dy == 0
        commands.push("h#{dx}")
        last_instruction_was_l = false
      else
        commands.push("#{last_instruction_was_l && ' ' || 'l'}#{dx},#{dy}")
        last_instruction_was_l = true

      point = point2

    commands.push('Z')

    commands.join('')

  compressed_rings.join('')

distance2 = (p1, p2) ->
  dx = p2[0] - p1[0]
  dy = p2[1] - p1[1]
  dx * dx + dy * dy

# Returns a <path class="state">
render_state_path = (path, topology, features) ->
  d = path(topojson.mesh(topology, topology.objects.counties, (a, b) -> a == b))
  d = compress_svg_path(d)
  '  <path class="state" transform="scale(0.1)" d="' + d + '"/>'

# Returns a <g class="counties"> full of <path data-fips-int="...">s
render_counties_g = (path, topology, geometries) ->
  ret = [ '  <g class="counties" transform="scale(0.1)">' ]

  for geometry in geometries
    # Minnesota has a weird FIPS code, 27000, for Lake Superior
    continue if /000$/.test(geometry.properties.fips_string)

    d = path(topojson.feature(topology, geometry))
    d = compress_svg_path(d)
    ret.push("    <path data-fips-int=\"#{+geometry.properties.fips_string}\" data-name=\"#{geometry.properties.name}\" d=\"#{d}\"/>")

  ret.push('  </g>')
  ret.join('\n')

# Returns a <g class="subcounties"> full of <path data-geoid="...">s
render_subcounties_g = (path, topology, geometries) ->
  ret = [ '  <g class="subcounties" transform="scale(0.1)">' ]

  for geometry in geometries
    d = path(topojson.feature(topology, geometry))
    d = compress_svg_path(d)
    ret.push("    <path data-geoid=\"#{+geometry.properties.geoid}\" data-name=\"#{geometry.properties.name}\" d=\"#{d}\"/>")

  ret.push('  </g>')
  ret.join('\n')

render_cities_g = (topology, geometries) ->
  ret = [ '  <g class="cities">' ]

  rendered_cities = [] # Track all dots we rendered; ensure we don't render them too close to one another
  cities = (topojson.feature(topology, geometry) for geometry in topology.objects.cities.geometries)
    .sort (a, b) ->
      # Prefer "Civil" to "Populated Place". Some states (e.g., VI) don't have
      # any cities, so we can't filter.
      p1 = a.properties
      p2 = b.properties
      ((p1 == 'Civil' && -1 || 0) - (p2 == 'Civil' && -1 || 0)) || p2.population - p1.population || p1.name.localeCompare(p2.name)
  for city in cities
    p = city.geometry.coordinates

    continue if rendered_cities.find((p2) -> distance2(p, p2) < 25 * 25)

    x = p[0].toFixed(1)
    y = p[1].toFixed(1)
    ret.push("    <circle r=\"3\" cx=\"#{x}\" cy=\"#{y}\"/>")
    ret.push("    <text x=\"#{x}\" y=\"#{y}\">#{city.properties.name}</text>")

    rendered_cities.push(p)
    break if rendered_cities.length == 3
  ret.push('  </g>')
  ret.join('\n')

render_state_svg = (state_code, features, callback) ->
  output_filename = "./output/#{state_code}.svg"

  if !features.counties.length
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
  ]

  data.push(render_state_path(path, topology, topology.objects.counties))
  data.push(render_counties_g(path, topology, topology.objects.counties.geometries))
  if topology.objects.subcounties?.geometries?.length
    data.push(render_subcounties_g(path, topology, topology.objects.subcounties.geometries))
  if topology.objects.cities.geometries.length
    data.push(render_cities_g(topology, topology.objects.cities.geometries))

  data.push('</svg>')

  data_string = data.join('\n')
  fs.writeFile(output_filename, data_string, callback)

render_all_states = (callback) ->
  pending_states = Object.keys(features_by_state).sort()

  step = ->
    if pending_states.length > 0
      state_code = pending_states.shift()
      render_state_svg state_code, features_by_state[state_code], (err) ->
        throw err if err
        process.nextTick(step)
    else
      callback(null)

  step()

geo_loader.load_all_features (err, key_to_features) ->
  throw err if err

  organize_features('cities', key_to_features.cities)
  organize_features('counties', key_to_features.counties)

  [ 'NH' ].forEach (key) ->
    organize_subcounty_features(key, key_to_features[key])

  [ 'AS', 'GU', 'MP' ].forEach (key) ->
    organize_territory_features(key, key_to_features[key])

  render_all_states (err) ->
    throw err if err
    console.log('Done! Now try `cp output/*.svg ../assets/maps/states/`')
