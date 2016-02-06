fs = require('fs')
get = require('simple-get')
tar = require('tar-fs')
unzip = require('unzip')
shapefile = require('shapefile')
zlib = require('zlib')

DataFiles = require('./DataFiles')

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

    deflated = if /\.zip$/.test(url)
      res.pipe(unzip.Extract(path: './input'))
    else
      res.pipe(zlib.createGunzip()).pipe(tar.extract('./input'))

    deflated
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
