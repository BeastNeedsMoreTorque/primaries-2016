d3 = require('d3')
deep_copy = require('deep-copy')
fs = require('fs')
topojson = require('topojson')
jsts = require('jsts')

require('d3-geo-projection')(d3)

MaxWidth = 350
MaxHeight = 350
MinDistanceBetweenCities = 35 # px, vertically or horizontally

BigTopojsonOptions =
  'pre-quantization': 6000
  'post-quantization': 2000
  'coordinate-system': 'cartesian'
  'minimum-area': 5
  'preserve-attached': false
  'property-transform': (f) -> f.properties

TinyTopojsonOptions =
  'pre-quantization': 5000
  'post-quantization': 200
  'coordinate-system': 'cartesian'
  'minimum-area': 10
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

# AP tallies Alaska votes by congressional district for these states.
#
# Our HACK is to overwrite counties with districts. They both look like FIPS
# codes.
organize_alaska_districts = (features) ->
  features_by_state.AK.subcounties = for feature in features
    p = feature.properties

    type: 'Feature'
    geometry: feature.geometry
    properties:
      GEOID: p.GEOID
      NAME: p.NAMELSAD

# On the Friday before Super Tuesday, AP decided to report MN results by
# congressional district.
organize_minnesota_districts = (features) ->
  features_by_state.MN.subcounties = for feature in features when feature.properties.STATEFP == '27'
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
  # First, round to one decimal and multiply by 10
  #
  # Do this while we're still dealing with absolute coordinates.
  int_path = path.replace(/\.(\d)\d+/g, (__, one_decimal) -> one_decimal)

  last_point = null
  last_instruction = null
  out = [] # Array of String instructions with coordinates

  next_instruction_index = 0
  instr_regex = /([a-zA-Z ])(?:(\d+),(\d+))?/g

  while (match = instr_regex.exec(int_path)) != null
    if next_instruction_index != instr_regex.lastIndex - match[0].length
      throw new Error("Found a non-instruction at position #{next_instruction_index} of path #{int_path}. Next instruction was at position #{instr_regex.lastIndex}. Aborting.")
    next_instruction_index = instr_regex.lastIndex

    switch match[1]
      when 'Z'
        last_instruction = 'Z'
        last_point = null
        out.push('Z')

      when 'M'
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
            out.push("v#{dy}")
          else if dy == 0
            last_instruction = 'h'
            out.push("h#{dx}")
          else
            instruction = if last_instruction == 'l' then ' ' else 'l'
            last_instruction = 'l'
            out.push("#{instruction}#{dx},#{dy}")

        last_point = point

      else
        throw "Need to handle SVG instruction #{match[0]}. Original path: #{path}. Aborting."

  if next_instruction_index != int_path.length
    throw "Unhandled SVG instruction at end of path: #{int_path.slice(next_instruction_index)}"

  out.join('')

distance2 = (p1, p2) ->
  dx = p2[0] - p1[0]
  dy = p2[1] - p1[1]
  dx * dx + dy * dy

# Returns a <path class="state">
render_state_path = (path, topology) ->
  d = path(topojson.feature(topology, topology.objects.state))
  d = compress_svg_path(d)
  '  <path class="state" transform="scale(0.1)" d="' + d + '"/>'

# Returns a <path class="mesh">
render_mesh_path = (path, topology, key) ->
  mesh = topojson.mesh(topology, topology.objects[key], (a, b) -> a != b)
  d = path(mesh)
  if d
    d = compress_svg_path(d)
    '  <path class="mesh" transform="scale(0.1)" d="' + d + '"/>'
  else
    # DC, for instance, has no mesh
    ''

# Returns a <g class="counties"> full of <path data-fips-int="...">s
render_counties_g = (path, topology, geometries) ->
  ret = [ '  <g class="counties" transform="scale(0.1)">' ]

  for geometry in geometries
    d = path(topojson.feature(topology, geometry))
    d = compress_svg_path(d)
    ret.push("    <path data-fips-int=\"#{+geometry.properties.fips_string}\" data-name=\"#{geometry.properties.name}\" d=\"#{d}\"/>")

  ret.push('  </g>')
  ret.join('\n')

# Returns a <g class="subcounties"> full of <path data-geo-id="...">s
render_subcounties_g = (path, topology, geometries) ->
  ret = [ '  <g class="subcounties" transform="scale(0.1)">' ]

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

    x = p[0].toFixed(1)
    y = p[1].toFixed(1)
    ret.push("    <circle r=\"3\" cx=\"#{x}\" cy=\"#{y}\"/>")
    ret.push("    <text x=\"#{x}\" y=\"#{y}\">#{city.properties.name}</text>")

    rendered_cities.push(p)
    break if rendered_cities.length == 3
  ret.push('  </g>')
  ret.join('\n')

render_state_svg = (state_code, feature_set, options, callback) ->
  output_filename = "./output/#{state_code}.svg"

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
render_state = (state_code, callback) ->
  console.log("#{state_code}:")

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

  render_state_svg state_code, feature_set, {}, (err) ->
    return callback(err) if err
    render_tiny_state_svg(state_code, jsts_state_multipolygon, {}, callback)

render_all_states = (callback) ->
  pending_states = Object.keys(features_by_state).sort()
    .filter((s) -> s == 'MN' || s == 'AK')

  step = ->
    if pending_states.length > 0
      state_code = pending_states.shift()
      render_state state_code, (err) ->
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

  organize_alaska_districts(key_to_features.AK)
  organize_minnesota_districts(key_to_features.congressional_districts)

  [ 'MA', 'NH', 'VT' ].forEach (key) ->
    organize_subcounty_features(key, key_to_features[key])

  [ 'AS', 'GU', 'MP' ].forEach (key) ->
    organize_territory_features(key, key_to_features[key])

  render_all_states (err) ->
    throw err if err

    render_DA key_to_features.DA, (err) ->
      throw err if err
      console.log('Done! Now try `cp -r output/* ../assets/maps/states/`')
