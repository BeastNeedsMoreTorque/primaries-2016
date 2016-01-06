var state_svg_nodes = {}; // code -> svg

d3.selectAll('.state-map')
  .each(function() {
    var state_code = this.getAttribute('data-state-code');
    var svg = d3.select(this).append('svg')
      .attr('data-state-code', state_code)
      .attr('width', '100%')
      .attr('height', '100%');
    state_svg_nodes[state_code] = svg.node();
  });

if (Object.keys(state_svg_nodes).length > 0) {
  // Defers until the svg has been rendered, empty, on the page. Then calls
  // next(width, height).
  function wait_for_svg_to_have_size_then(svg, next) {
    var node = svg.node();
    var bbox = node.parentNode.getBoundingClientRect();
    if (bbox.width > 0 || bbox.height > 0) {
      var width = Math.floor(bbox.width);
      var height = Math.floor(bbox.height);
      svg.attr('width', width).attr('height', height);
      next(width, height);
    } else {
      window.setTimeout(function() { wait_for_svg_to_have_size_then(svg, next); }, 10);
    }
  }

  function compute_projection(features, width, height) {
    // http://stackoverflow.com/questions/14492284/center-a-map-in-d3-given-a-geojson-object
    var projection = d3.geo.albers()
      .scale(1)
      .translate([0, 0]);

    var path = d3.geo.path()
      .projection(projection);

    var b = path.bounds({ type: 'FeatureCollection', features: features });
    var s = .95 / Math.max((b[1][0] - b[0][0]) / width, (b[1][1] - b[0][1]) / height);
    var t = [(width - s * (b[1][0] + b[0][0])) / 2, (height - s * (b[1][1] + b[0][1])) / 2];

    projection.scale(s).translate(t);
    return projection;
  }

  function on_click_county(d) {
    console.log(d);
  }

  function build_maps(us) {
    Object.keys(state_svg_nodes).forEach(function(state_code) {
      var state = StatesByCode[state_code];
      var node = state_svg_nodes[state_code];
      var svg = d3.select(node);

      wait_for_svg_to_have_size_then(svg, function(width, height) {
        var county_features = topojson.feature(us, us.objects.counties).features
          .filter(function(d) { return Math.floor(d.id / 1000) == state.fipsInt; });

        var projection = compute_projection(county_features, width, height);

        var path = d3.geo.path()
          .projection(projection);

        svg.selectAll('path')
          .data(county_features)
          .enter().append('path')
            .attr('class', 'county')
            .attr('id', function(d) { return d.id; })
            .attr('d', path)
            .on('click', on_click_county)
            ;
      });
    });
  }

  d3.json('/2016/topojson/us.json', function(err, us) {
    if (err) throw err;

    build_maps(us);
  });
}
