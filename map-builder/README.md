# Running

To build all maps for this project, writing to `./output`:

1. Install [NodeJS](https://nodejs.org/en/)
  * On Mac OS X: `brew install node`
  * On Fedora 23: `curl --silent --location https://rpm.nodesource.com/setup_5.x | sudo bash -`
2. `cd` here
3. `npm install`
4. `npm run main`

# What it does

1. Downloads inputs into `./input`:
  * [Cities and Towns](http://dds.cr.usgs.gov/pub/data/nationalatlas/citiesx010g_shp_nt00962.tar.gz)
  * [Counties](http://dds.cr.usgs.gov/pub/data/nationalatlas/countyp010g.shp_nt00934.tar.gz)
2. Loads the `.shp` features into memory, grouping by state
3. For each state:
  1. Calculates that state's bounding box (filtering all features by state code)
  2. From the bounding box, calculates parameters for an equal-area conic (Albers) projection
  3. Finds the three largest cities within that state
  4. Renders an SVG with that projection, with a &lt;g&gt; of &lt;path&gt;s for counties and a &lt;g&gt; of &lt;circle&gt;+&lt;text&gt;s for cities.
