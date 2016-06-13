d3 = require('d3')
deep_copy = require('deep-copy')
fs = require('fs')
topojson = require('topojson')
jsts = require('jsts')

require('d3-geo-projection')(d3)

MaxWidth = 1000
MaxHeight = 1000
MinDistanceBetweenCities = 80 # px, vertically or horizontally

BigTopojsonOptions =
  'pre-quantization': 10000
  'post-quantization': 1000
  'coordinate-system': 'cartesian'
  'minimum-area': 50
  'preserve-attached': false
  'property-transform': (f) -> f.properties

TinyTopojsonOptions =
  'pre-quantization': 10000
  'post-quantization': 1000
  'coordinate-system': 'cartesian'
  'minimum-area': 200
  'preserve-attached': false
  'property-transform': (f) -> {}

# Something akin to a GeoJSON Feature, but the geometry is JSTS.
#
# Why? Because we need to do geo transformations. GeoJSON has no useful
# libraries, and topojson can't handle errors in the geometry.
class JstsFeature
  constructor: (@geometry, @properties) ->

  toJSON: ->
    type: 'Feature'
    geometry: JSON.parse(JSON.stringify(GeoJSONWriter.write(@geometry)))
    properties: @properties

class StateFeatureSet
  constructor: (@jsts_state_multipolygon, @jsts_county_features, @jsts_subcounty_features, @city_features) ->

  # Outputs hash of state, counties, subcounties and cities -- all GeoJSON objects
  toJSON: ->
    features = (fs) ->
      ret = fs.map((f) -> f.toJSON())
        .filter((f) -> f.geometry?)
        .filter((f) -> f.geometry.type != 'Polygon' || f.geometry.coordinates[0].length > 0) # MP has a null geometry

    state: { type: 'Feature', geometry: JSON.parse(JSON.stringify(GeoJSONWriter.write(@jsts_state_multipolygon))) }
    counties: { type: 'FeatureCollection', features: features(@jsts_county_features) }
    subcounties: { type: 'FeatureCollection', features: features(@jsts_subcounty_features) }
    cities: { type: 'FeatureCollection', features: @city_features }

GeoJSONReader = new jsts.io.GeoJSONReader()
GeoJSONWriter = new jsts.io.GeoJSONWriter()
GeoJSONCRS =
  type: 'name',
  properties:
    name: 'urn:ogc:def:crs:OGC:1.3:CRS84'

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

# AP tallies AK and ND votes by state congressional district.
#
# Our HACK is to overwrite counties with districts. They both look like FIPS
# codes for Alaska. ND, it's four-digit, so it doesn't look like FIPS codes.
organize_state_congressional_districts = (state_code, features) ->
  features_by_state[state_code].subcounties = for feature in features
    p = feature.properties

    type: 'Feature'
    geometry: feature.geometry
    properties:
      GEOID: p.GEOID
      NAME: p.NAMELSAD

# AP tallies WY results by pair-of-counries for Wyoming.
organize_wyoming_gop_counties = ->
  in_progress =
    51025: { geometries: [], names: [], fips: [ '56001', '56025' ] }
    51026: { geometries: [], names: [], fips: [ '56005', '56019' ] }
    51027: { geometries: [], names: [], fips: [ '56009', '56027' ] }
    51028: { geometries: [], names: [], fips: [ '56011', '56045' ] }
    51029: { geometries: [], names: [], fips: [ '56013', '56029' ] }
    51030: { geometries: [], names: [], fips: [ '56015', '56031' ] }
    51031: { geometries: [], names: [], fips: [ '56017', '56043' ] }
    51032: { geometries: [], names: [], fips: [ '56021' ] }
    51033: { geometries: [], names: [], fips: [ '56033', '56003' ] }
    51034: { geometries: [], names: [], fips: [ '56037', '56007' ] }
    51035: { geometries: [], names: [], fips: [ '56039', '56035' ] }
    51036: { geometries: [], names: [], fips: [ '56041', '56023' ] }

  fips_to_geo_id = {}
  for geo_id, o of in_progress
    for fips in o.fips
      fips_to_geo_id[fips] = geo_id

  for feature in features_by_state.WY.counties
    p = feature.properties
    fips = p.ADMIN_FIPS
    name = p.ADMIN_NAME || p.NAME
    geo_id = fips_to_geo_id[fips]
    throw new Error("What to do with fips code #{fips}?") if !geo_id

    o = in_progress[geo_id]

    o.geometries.push(feature.geometry)
    o.names.push(name)

  features_by_state.WY.subcounties = for geo_id, o of in_progress
    type: 'Feature'
    properties: { GEOID: geo_id, NAME: o.names.join(', ') }
    geometry:
      type: 'MultiPolygon'
      coordinates: o.geometries.map((g) -> g.coordinates)

# AP tallies DC votes by ward.
organize_dc_wards = ->
  for feature in features_by_state.DC.subcounties
    # DC's county FIPS code is 11001. There are no other FIPS codes that start
    # with "11", so "1101X" is safe.
    feature.properties.GEOID = "1101#{feature.properties.WARD}"

# In some states, AP only reports by congressional district
#
# Don't render Alaska (State House District ID 2XXX) and Kansas
# (US District ID 20XX) on the same page!
#
# @param state_code State code
# @param fips_string 2-digit FIPS code of the state (for filtering districts)
# @param all_congressional_district_features An Array of Features
organize_congressional_district_features = (state_code, fips_string, all_congressional_district_features) ->
  features = (f for f in all_congressional_district_features when f.properties.STATEFP == fips_string)

  features_by_state[state_code].subcounties = for feature in features
    p = feature.properties

    type: 'Feature'
    geometry: feature.geometry
    properties:
      GEOID: p.GEOID
      NAME: p.NAMELSAD

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

calculate_projection_width_height = (state_geojson) ->
  # Calculate projection parameters...
  alaska_safe_projection = (arr) -> [ (if arr[0] > 172 then -360 + arr[0] else arr[0]), arr[1] ]
  path1 = d3.geo.path().projection(alaska_safe_projection)
  ll_bounds = path1.bounds(state_geojson)

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
  b = path2.bounds(state_geojson)

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
  ret = {}
  for key in Object.keys(features)
    ret[key] = d3.geo.project(features[key], projection)
  ret

topojsonize = (features_json, options) ->
  # Modeled after topojson's bin/topojson
  x = deep_copy(features_json)
  topology = topojson.topology(x, options)
  topojson.simplify(topology, options)
  topojson.filter(topology, options)
  topojson.prune(topology, options)
  topology

compress_svg_path = (path) ->
  # First off, round everything. That'll give us four decimals, like we want
  int_path = path.replace(/\.\d+/g, '')

  last_point = null
  last_instruction = null
  out = [] # Array of String instructions with coordinates

  next_instruction_index = 0
  instr_regex = /([a-zA-Z ])(?:(\d+),(\d+))?/g

  # We want to bundle "v" and "h" instructions together, where applicable.
  # (There are lots and lots of them in the congressional-district data.)
  current_line =
    instruction: null
    d: null # dx or dy

  flush = () ->
    if current_line.instruction?
      out.push("#{current_line.instruction}#{current_line.d}")
      current_line.instruction = current_line.d = null

  start_or_continue_current_line = (instruction, d) ->
    if current_line.instruction == instruction && current_line.d * d > 0
      current_line.d += d
    else
      flush()
      current_line.instruction = instruction
      current_line.d = d

  while (match = instr_regex.exec(int_path)) != null
    if next_instruction_index != instr_regex.lastIndex - match[0].length
      throw new Error("Found a non-instruction at position #{next_instruction_index} of path #{int_path}. Next instruction was at position #{instr_regex.lastIndex}. Aborting.")
    next_instruction_index = instr_regex.lastIndex

    switch match[1]
      when 'Z'
        flush()
        last_instruction = 'Z'
        last_point = null
        out.push('Z')

      when 'M'
        flush()
        point = [ +match[2], +match[3] ]

        last_point = point
        last_instruction = 'M'
        out.push("M#{point[0]},#{point[1]}")

      when 'L'
        if !last_point?
          throw 'Got an L instruction without a previous point. Aborting.'

        point = [ parseInt(match[2]), parseInt(match[3]) ]
        dx = point[0] - last_point[0]
        dy = point[1] - last_point[1]

        if dx != 0 || dy != 0
          if dx == 0
            last_instruction = 'v'
            start_or_continue_current_line('v', dy)
          else if dy == 0
            last_instruction = 'h'
            start_or_continue_current_line('h', dx)
          else
            flush()
            instruction = if last_instruction == 'l' then ' ' else 'l'
            last_instruction = 'l'
            out.push("#{instruction}#{dx},#{dy}")

        last_point = point

      else
        throw "Need to handle SVG instruction #{match[0]}. Original path: #{path}. Aborting."

  if next_instruction_index != int_path.length
    throw "Unhandled SVG instruction at end of path: #{int_path.slice(next_instruction_index)}"

  flush()
  out.join('')

distance2 = (p1, p2) ->
  dx = p2[0] - p1[0]
  dy = p2[1] - p1[1]
  dx * dx + dy * dy

# Returns a <path class="state">
render_state_path = (path, topology) ->
  d = path(topojson.feature(topology, topology.objects.state))
  d = compress_svg_path(d)
  '  <path class="state" d="' + d + '"/>'

# Returns a <path class="mesh">
render_mesh_path = (path, topology, key) ->
  mesh = topojson.mesh(topology, topology.objects[key], (a, b) -> a != b)
  d = path(mesh)
  if d
    d = compress_svg_path(d)
    '  <path class="mesh" d="' + d + '"/>'
  else
    # DC, for instance, has no mesh
    ''

# Returns a <g class="counties"> full of <path data-fips-int="...">s
render_counties_g = (path, topology, geometries) ->
  ret = [ '  <g class="counties">' ]

  for geometry in geometries
    d = path(topojson.feature(topology, geometry))
    d = compress_svg_path(d)
    ret.push("    <path data-fips-int=\"#{+geometry.properties.fips_string}\" data-name=\"#{geometry.properties.name}\" d=\"#{d}\"/>")

  ret.push('  </g>')
  ret.join('\n')

# Returns a <g class="subcounties"> full of <path data-geo-id="...">s
render_subcounties_g = (path, topology, geometries) ->
  ret = [ '  <g class="subcounties">' ]

  for geometry in geometries
    d = path(topojson.feature(topology, geometry))
    d = compress_svg_path(d)
    ret.push("    <path data-geo-id=\"#{+geometry.properties.geo_id}\" data-name=\"#{geometry.properties.name}\" d=\"#{d}\"/>")

  ret.push('  </g>')
  ret.join('\n')

render_cities_g = (city_features) ->
  ret = [ '  <g class="cities">' ]

  rendered_cities = [] # Track all dots we rendered; ensure we don't render them too close to one another
  city_features
    .sort (a, b) ->
      # Prefer "Civil" to "Populated Place". Some states (e.g., VI) don't have
      # any cities, so we can't filter.
      p1 = a.properties
      p2 = b.properties
      ((p1.feature == 'Civil' && -1 || 0) - (p2.feature == 'Civil' && -1 || 0)) || p2.population - p1.population || p1.name.localeCompare(p2.name)

  for city in city_features
    p = city.geometry.coordinates

    continue if rendered_cities.find((p2) -> distance2(p, p2) < MinDistanceBetweenCities * MinDistanceBetweenCities)

    x = p[0].toFixed(0)
    y = p[1].toFixed(0)
    ret.push("    <circle r=\"7\" cx=\"#{x}\" cy=\"#{y}\"/>")
    ret.push("    <text x=\"#{x}\" y=\"#{y}\">#{city.properties.name}</text>")

    rendered_cities.push(p)
    break if rendered_cities.length == 3
  ret.push('  </g>')
  ret.join('\n')

render_state_svg = (state_code, feature_set, options, callback) ->
  output_filename = "./output/#{options.output_name || state_code}.svg"

  console.log("Rendering #{output_filename}...")

  features_json = feature_set.toJSON()
  [ projection, width, height ] = options.projection || calculate_projection_width_height(features_json.state)
  features_json = project_features(features_json, projection)

  topology = topojsonize(features_json, BigTopojsonOptions)

  # Note that our viewBox is width/height multiplied by 10. We round everything to integers to compress
  data = [
    '<?xml version="1.0" encoding="utf-8"?>'
    '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">'
    "<svg version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\" width=\"#{width}\" height=\"#{height}\" viewBox=\"0 0 #{width} #{height}\">"
  ]

  path = d3.geo.path().projection(null)

  data.push(render_state_path(path, topology))

  if topology.objects.subcounties?.geometries?.length
    data.push(render_subcounties_g(path, topology, topology.objects.subcounties.geometries))
    data.push(render_mesh_path(path, topology, 'subcounties'))
  else
    data.push(render_counties_g(path, topology, topology.objects.counties.geometries))
    data.push(render_mesh_path(path, topology, 'counties'))

  if features_json.cities.features.length
    data.push(render_cities_g(features_json.cities.features))

  data.push('</svg>')

  data_string = data.join('\n')

  fs.writeFile(output_filename, data_string, callback)

render_tiny_state_svg = (state_code, jsts_state_multipolygon, options, callback) ->
  output_filename = "./output/tiny/#{state_code}.svg"
  console.log("Rendering #{output_filename}...")

  features_json = { state: { type: 'Feature', geometry: GeoJSONWriter.write(jsts_state_multipolygon) } }
  [ projection, width, height ] = options.projection || calculate_projection_width_height(features_json.state)
  features_json = project_features(features_json, projection)
  topology = topojsonize(features_json, TinyTopojsonOptions)

  path = d3.geo.path().projection(null)

  # Note that our viewBox is width/height multiplied by 10. We round everything to integers to compress
  data = [
    '<?xml version="1.0" encoding="utf-8"?>'
    '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">'
    "<svg version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\" width=\"#{width}\" height=\"#{height}\" viewBox=\"0 0 #{width} #{height}\">"
    render_state_path(path, topology)
    "<text x=\"#{width >> 1}\" y=\"#{height >> 1}\">#{state_code}</text>"
    "</svg>"
  ]

  data_string = data.join('\n')
  fs.writeFile(output_filename, data_string, callback)

# Turns a GeoJSON Geometry into a valid JSTS Geometry
geojson_geometry_to_jsts_geometry = (geojson_geometry) ->
  GeoJSONReader.read(geojson_geometry)
    .buffer(0) # make valid

# Transforms an Array of raw GeoJSON Features (from our geo loader) into an
# Array of JstsFeatures.
#
# Each Feature has "fips_string" and "name" properties.
grok_input_county_features = (input_county_features) ->
  for feature in input_county_features
    p = feature.properties

    new JstsFeature(
      geojson_geometry_to_jsts_geometry(feature.geometry),
      {
        fips_string: p.ADMIN_FIPS
        name: p.ADMIN_NAME || p.NAME
      }
    )

# Calculates the union of all county geometries
jsts_county_features_to_state_multipolygon = (jsts_county_features) ->
  jsts_geometries = jsts_county_features.map((f) -> f.geometry)
  jsts_union(jsts_geometries)

# Calculates the union of the given Array of Geometries.
#
# This method is because JSTS is unstable.
# jsts.operation.union.CascadedPolygonUnion doesn't work, and
# jsts_geometries.reduce((a, b) -> a.union(b)) is too slow. This is a
# compromise: not too slow, not too complex.
jsts_union = (jsts_geometries) ->
  # divide and conquer
  switch jsts_geometries.length
    when 0 then null
    when 1 then jsts_geometries[0]
    when 2 then jsts_geometries[0].union(jsts_geometries[1])
    else
      mid = jsts_geometries.length >> 1
      left = jsts_geometries.slice(0, mid)
      right = jsts_geometries.slice(mid)

      jsts_union([ jsts_union(left), jsts_union(right) ])

# Transforms an Array of raw GeoJSON features (from our geo loader) into an
# Array of JstsFeatures.
#
# Each geometry is intersected with the state MultiPolygon. That's because
# subcounty geometries are political boundaries: they extend into lakes and
# oceans.
#
# Each Feature has "geo_id" and "name" properties.
grok_input_subcounty_features = (input_subcounty_features, jsts_state_multipolygon) ->
  ret = []

  for feature in input_subcounty_features
    p = feature.properties
    geometry = geojson_geometry_to_jsts_geometry(feature.geometry)
    intersected_geometry = geometry.intersection(jsts_state_multipolygon)

    if intersected_geometry.getGeometryType() not in [ 'Polygon', 'MultiPolygon' ]
      throw new Error("Unexpected geometry type #{intersected_geometry.getGeometryType()}: " + JSON.stringify(intersected_geometry))

    if !intersected_geometry.isEmpty()
      ret.push(new JstsFeature(
        intersected_geometry,
        {
          geo_id: p.GEOID
          name: p.ADMIN_NAME || p.NAME
        }
      ))

  ret

# Transforms an Array of raw GeoJSON Features (from our geo loader) into an
# Array of GeoJSON Features.
#
# This is basically a pass-through. We filter out non-cities and we set the
# `name` and `population` properties on the output. Every Feature geometry is a
# Point.
grok_input_city_features = (input_city_features) ->
  for feature in input_city_features
    p = feature.properties
    
    type: 'Feature'
    geometry: feature.geometry
    properties:
      feature: p.FEATURE # We *want* 'Civil', but VT has no cities so we fall back to others
      name: p.ADMIN_NAME || p.NAME
      population: +p.POP_2010

# Writes output files for the given state code, reading from
# features_by_state[state_code]
render_state = (state_code, options, callback) ->
  console.log("#{options.output_name || state_code}:")

  input_county_features = features_by_state[state_code].counties
  input_subcounty_features = features_by_state[state_code].subcounties
  input_city_features = features_by_state[state_code].cities

  jsts_county_features = grok_input_county_features(input_county_features)
  jsts_state_multipolygon = jsts_county_features_to_state_multipolygon(jsts_county_features)
  jsts_subcounty_features = grok_input_subcounty_features(input_subcounty_features, jsts_state_multipolygon)
  city_features = grok_input_city_features(input_city_features)

  feature_set = new StateFeatureSet(
    jsts_state_multipolygon,
    jsts_county_features,
    jsts_subcounty_features,
    city_features
  )

  render_state_svg state_code, feature_set, options, (err) ->
    return callback(err) if err
    render_tiny_state_svg(state_code, jsts_state_multipolygon, {}, callback)

render_all_states = (callback) ->
  pending_states = Object.keys(features_by_state).sort()

  step = ->
    if pending_states.length > 0
      state_code = pending_states.shift()
      render_state state_code, {}, (err) ->
        return callback(err) if err
        process.nextTick(step)
    else
      callback(null)

  process.nextTick(step)

render_DA = (features, callback) ->
  # Merge all countries together. We want a MultiPolygon and topojson.mesh()
  # only returns a MultiLineString.
  jsts_country_geometries = for f in features
    new JstsFeature(geojson_geometry_to_jsts_geometry(f.geometry), { fips_string: '0', name: '' })
  jsts_world_multipolygon = jsts_county_features_to_state_multipolygon(jsts_country_geometries)

  # http://bl.ocks.org/mbostock/3757101
  projection = d3.geo.azimuthalEqualArea()
    .clipAngle(180 - 1e-3)
    .scale(237 * MaxWidth / 960)
    .translate([ MaxWidth / 2, MaxHeight / 2 ])
    .precision(.1)

  janky_options =
    projection: [ projection, MaxWidth, MaxHeight ]

  feature_set = new StateFeatureSet(
    jsts_world_multipolygon,
    jsts_country_geometries,
    [],
    []
  )

  render_state_svg 'DA', feature_set, janky_options, (err) ->
    return callback(err) if err
    render_tiny_state_svg 'DA', jsts_world_multipolygon, janky_options, (err) ->
      callback(err)

try
  fs.mkdirSync('./output/tiny')
catch e
  throw e if e.code != 'EEXIST'

geo_loader.load_all_features (err, key_to_features) ->
  throw err if err

  organize_features('cities', key_to_features.cities)
  organize_features('counties', key_to_features.counties)

  [ 'AK', 'ND' ].forEach (key) ->
    organize_state_congressional_districts(key, key_to_features[key])

  [ 'CT', 'MA', 'ME', 'NH', 'RI', 'VT' ].forEach (key) ->
    organize_subcounty_features(key, key_to_features[key])

  [ 'AS', 'GU', 'MP' ].forEach (key) ->
    organize_territory_features(key, key_to_features[key])

  [ [ 'KS', '20' ], [ 'MN', '27' ] ].forEach (arr) ->
    [ state_code, fips_string ] = arr
    organize_congressional_district_features(state_code, fips_string, key_to_features.congressional_districts)

  render_all_states (err) ->
    throw err if err

    # WY-GOP is an ugly hack. Heck, primaries are almost over; I'm lazy.
    organize_wyoming_gop_counties()
    render_state 'WY', { output_name: 'WY-GOP' }, (err) ->
      throw err if err

      # And DC-Dem is literally the very last one. Lazy hack again!
      organize_subcounty_features('DC', key_to_features.DC)
      organize_dc_wards()
      render_state 'DC', { output_name: 'DC-Dem' }, (err) ->
        throw err if err

        render_DA key_to_features.DA, (err) ->
          throw err if err
          console.log('Done! Now try `cp -r output/* ../assets/maps/states/`')
