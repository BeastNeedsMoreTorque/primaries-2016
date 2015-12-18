Tracks presidential primaries and election in 2016.

This is not a web app: it is a flat-file generator. It's designed to churn out
results so they're updated frequently and available to all.

In development mode, it spits out to the `dist/` directory. Use a simple HTTP
server to view the results: `script/serve` will put them at
[http://localhost:3000](http://localhost:3000).

## Paths

* `/primaries/R/AK`: Republican primary results in Alaska
* `/primaries/R/AK.json`: JSON data to update the page
* `/primaries/D/NY`: Democratic primary results in New York
* `/primaries/D/NY.json`: JSON data to update the page

## Scripts

`AP_API_KEY=abcdef script/update-2016-primaries`: update all pages representing 2016 primaries

... you can also use `AP_TEST=true` to populate the `dist/` directory with sample data.
