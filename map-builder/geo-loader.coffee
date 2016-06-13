fs = require('fs')
get = require('simple-get')
tar = require('tar-fs')
yauzl = require('yauzl') # unzip library
shapefile = require('shapefile')
zlib = require('zlib')

DataFiles = require('./DataFiles')

is_data_downloaded = (key, callback) ->
  data_file = DataFiles[key]
  shp_size = data_file.shp_size
  path = "#{__dirname}/input/#{data_file.basename}.shp"

  fs.stat path, (err, stats) ->
    ret = if err
      if err.errno == 'ENOENT'
        throw err
      else
        false
    else
      stats.size == shp_size

    callback(null, ret)

untar_stream = (stream, outdir, callback) ->
  res
    .pipe(zlib.createGunzip())
    .pipe(tar.extract("#{__dirname}/input"))
    .on('error', (err) -> throw err)
    .on('finish', -> callback())

unzip_buffer = (buffer, outdir, callback) ->
  yauzl.fromBuffer buffer, (err, zipfile) ->
    throw err if err

    zipfile.on('end', callback)
    zipfile.on 'entry', (entry) ->
      zipfile.openReadStream entry, (err, readStream) ->
        throw err if err

        readStream
          .pipe(fs.createWriteStream(entry.fileName))
          .on('end', -> zipfile.readEntry())
    zipfile.readEntry()

download_data = (key, callback) ->
  data_file = DataFiles[key]
  basename = data_file.basename
  url = data_file.url

  console.log("GET #{url}...")
  get.concat url, (err, res, buffer) ->
    throw err if err

    if /\.zip$/.test(url)
      unzip_buffer(buffer, "#{__dirname}/input", callback)
    else
      untar_stream(res, "#{__dirname}/input", callback)

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
    shp_filename = "#{__dirname}/input/#{basename}.shp"
    shapefile.read shp_filename, (err, feature_collection) ->
      throw err if err

      feature_collection.features = feature_collection.features.filter (f) ->
        # Minnesota has a weird FIPS code, 27000, for Lake Superior
        return false if /000$/.test(f.properties.ADMIN_FIPS || '')

        true

      callback(null, feature_collection.features)

# Calls callback with a mapping from DataFiles key to Array of GeoJSON features
load_all_features = (callback) ->
  ret = {} # key -> feature_collection.features

  to_load = Object.keys(DataFiles)

  step = ->
    if to_load.length == 0
      callback(null, ret)
    else
      key = to_load.pop()
      load_features key, (err, features) ->
        return callback(err) if err

        ret[key] = features
        process.nextTick(step)

  step()

module.exports =
  load_features: load_features
  load_all_features: load_all_features
