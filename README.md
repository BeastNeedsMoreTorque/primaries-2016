Tracks presidential primaries and election in 2016.

This is not a web app: it is a flat-file generator. It's designed to churn out
results so they're updated frequently and available to all.

## Installation

1. Install [rvm](http://rvm.io)
2. `gem install bundler`
3. `bundle install`
4. `script/build-assets`
5. `AP_API_KEY=abcdefg script/build-2016-primaries-from-scratch`
6. (periodically) `AP_API_KEY=abcdefg script/update-2016-primaries`

## Developing

This is a static website, stored in the `dist/` directory. Run `script/serve` to
serve it at [http://localhost:3000](http://localhost:3000).

Set the environment variable `AP_TEST=true` to incorporate test data from the
Associated Press.

## Paths

* `/primaries/R/AK`: Republican primary results in Alaska
* `/primaries/R/AK.json`: JSON data to update the page
* `/primaries/D/NY`: Democratic primary results in New York
* `/primaries/D/NY.json`: JSON data to update the page
