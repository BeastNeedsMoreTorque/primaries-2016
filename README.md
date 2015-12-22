Tracks presidential primaries and election in 2016.

This is not a web app: it is a flat-file generator. It's designed to churn out
results so they're updated frequently and available to all.

# Installation

1. Install [rvm](http://rvm.io)
2. `gem install bundler`
3. `bundle install`
4. `script/build-assets`
5. `AP_API_KEY=abcdefg script/build-2016-primaries-from-scratch`
6. (periodically) `AP_API_KEY=abcdefg script/update-2016-primaries`

# Developing

This is a static website, stored in the `dist/` directory. Run `script/serve` to
serve it at [http://localhost:3000](http://localhost:3000).

Set the environment variable `AP_TEST=true` to incorporate test data from the
Associated Press.

# Endpoints

* `/primaries/GOP/AK`: Republican primary results in Alaska
* `/primaries/Dem/NY`: Democratic primary results in New York

# Architecture

An build has two phases:

1. Pull the newest data from the AP Elections API
2. Build our static files (HTML, CSS, JavaScript, JSON)

The AP Elections API has severe quota restrictions. We try and avoid calls to
it whenever possible. We dump our HTML response JSON into `cache/ap`.

You can use or ignore each level of the cache using the following commands:

* To force-update the cache, run `script/build-primaries-from-scratch`.
* To update only what's needed, run `script/update-primaries`.
* To rebuild HTML/JSON after code changes, relying entirely on cached data, run
  `script/build-primaries`.
* To serve at [http://localhost:3000](http://localhost:3000) and rebuild every
  time code changes, run `script/serve`.
