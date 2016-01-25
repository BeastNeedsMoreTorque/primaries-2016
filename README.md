Tracks presidential primaries and election in 2016.

This is not a web app: it is a flat-file generator. It's designed to churn out
results so they're updated frequently and available to all.

# Installation

1. Install [rvm](http://rvm.io)
2. `gem install bundler`
3. `bundle install`
4. (for dev) `AP_API_KEY=abcdefg script/serve` and `rspec`
5. (for upload to s3) `AP_API_KEY=abcdefg script/build && script/upload`
6. (to ping AP for new data and rebuild) `AP_API_KEY=abcdefg script/update-primaries [YYYY-MM-DD ...]`

Bundle install problems? Maybe install
[capybara-webkit dependencies](https://github.com/thoughtbot/capybara-webkit/wiki/Installing-Qt-and-compiling-capybara-webkit). On Fedora 23, `ln -s /usr/bin/qmake-qt5 $HOME/bin/qmake`.

# Developing

This is a static website, stored in the `dist/` directory. Run `script/serve` to
serve it at [http://localhost:3000/2016](http://localhost:3000/2016). (You can
still run `script/update-primaries` periodically while this is running.)

Finally, if you run `rspec` directly you'll run automated tests. You must
have `script/serve` running in another console (to serve the files). This will
overwrite all HTML files once per test. Run `script/build` again to revert to
the results AP gives.

# Configuration

To set an option, use an environment variable.
([12factor.net rationale](http://12factor.net/config)). Every command may read
some of these variables.

| Variable | What it does |
| -------- | ------------ |
| `AP_API_KEY=...` | API key from the Associated Press |
| `AP_TEST=true` | Adds `?test=true` to AP API requests |
| `AWS_ACCESS_KEY`, etc | [Authenticates](http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/set-up-ec2-cli-linux.html) `script/upload` with Amazon Web Services |
| `S3_BUCKET` | Where to upload files with `script/upload` |
| `LOG_LEVEL=debug` | Produces more output |
| `DEBUG_ASSETS=true` | Disables JS/CSS minimization |
| `ASSET_HOST=assets.mydomain.com` | Prefixes asset URLs with `"//assets.mydomain.com"` |
| `LAST_DATE=YYYY-MM-DD` | Makes scripts produce race-day pages up until the given date (inclusive), and disables the rest |
| `RPROF=true` | Makes `script/build` use [ruby-prof](https://github.com/ruby-prof/ruby-prof) to dump wall-time profiling data to `./profile.html` |

# Production

While this is a static website, we do update it often. We run a simple, not-HTTP
server called `production-server` which handles various tasks:

* It updates from Pollster from time to time
* It updates from the AP API from time to time
* It builds and pushes to S3 after each update

## To install on a production machine

We control this server with [Capistrano](http://capistranorb.com/).
`cap staging deploy` will gracefully kill the previously-running
`production-server`, pull new code, and start a new `production-server`.
Here's the full list of commands:

* `cap production deploy`: update code, start/restart `production-server`. Will
  install correctly on a fresh server, prompting for the AP API key.
* `cap production reset_env`: prompts for a new AP API key.
* `cap production tell-server command='poll_dates 2016-02-01'`: give the server
  a command. Commands are:
  * `poll_dates [YYYY-MM-DD ...]`: updates AP data for races that day
  * `exit`: terminates the server gracefully

## To adjust schedule

On a race day, we want frequent updates of a specific date; other days, we'll
probably want to do less.

We adjust this schedule in this git repo. See `config/schedule.rb`.

Race day? Adjust `config/schedule.rb` and run `cap production deploy`.

## To change copy

1. Update the copy on Google Docs, at
   https://docs.google.com/document/d/1NqASd8jSJk85wZsvNlt4htsQcuDeDHBb0kQJFYzET3w/edit.
2. Run `script/update-copy`.
3. Check the `script/serve` output on localhost.
4. Run `git commit; git push; cap staging deploy` and test on staging.
5. Run `cap production deploy` and test on production.

# Endpoints

* `/2016/primaries`: Landing page page.
* `/2016/primaries/YYYY-MM-DD`: Dashboard for primaries on a certain day.
* `/2016/primaries/YYYY-MM-DD.json`: New numbers for YYYY-MM-DD. Includes
  county-level vote counts.
* `/2016/primaries/right-rail`: Embeddable right rail.
* `/2016/primaries/mobile-ad`: Embeddable mobile ad.
* `/2016/primaries/splash`: Embeddable splash.
* `/2016/javascripts/pym.min.js`: [Pym.js](http://blog.apps.npr.org/pym.js/):
  the embeddable endpoints call `new pym.Child();`, so the code that embeds
  them should use `pym.min.js` and call `new pym.Parent(...);`.

To build these files, we iterate over `app/views/*.rb` and run
`[SomethingView].generate_all` on each class. The `generate_all` method will
call `BaseView.generate_for_view(something_view)`, which will render the HAML
markup in `app/templates/something-view.html.haml`.

# Architecture

A build has three phases:

1. Pull the newest data from the AP Elections API
2. Build our static files (HTML, CSS, JavaScript, JSON)
3. Upload the static files to S3

The AP Elections API has severe quota restrictions. We try and avoid calls to
it whenever possible. We dump our HTML response JSON into `cache/`.

You can use or ignore each level of the cache using the following commands:

* To force-update the cache, run `script/build-primaries-from-scratch`.
* To update only what's needed, run `script/update-primaries YYYY-MM-DD`, where
  `YYYY-MM-DD` is the date of elections. This will update delegate and vote
  counts so they are the most recent.
* To rebuild HTML/JSON after code changes, relying entirely on cached data, run
  `script/build-primaries`.
* To serve at [http://localhost:3000](http://localhost:3000) and rebuild every
  time code changes, run `script/serve`. This will also call `rspec` whenever
  code changes, so you can't help but see test results :).
* To upload to S3, run `script/upload`. You'll need to set `AWS_ACCESS_KEY_ID`,
  `AWS_SECRET_ACCESS_KEY` and `AWS_REGION` in your environment.

# Sources

Here's an attempt to document all the sources of information we build upon.

* `app/collections/states.csv`: states and FIPS codes from Wikipedia; delegate
  counts from AP-emailed Excel file, `2016 State Party Delegate Numbers_121715.xlsx`
* Vote counts, candidate list, delegate counts: AP's API
