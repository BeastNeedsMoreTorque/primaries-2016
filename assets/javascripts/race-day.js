var svg_nodes = {}; // key -> svg

d3.selectAll('.state-map')
  .each(function() {
    var party_id = this.getAttribute('data-party-id');
    var state_code = this.getAttribute('data-state-code');
    var key = party_id + '-' + state_code;
    var svg = d3.select(this).append('svg')
      .attr('data-state-code', state_code)
      .attr('data-party-id', party_id)
      .attr('width', '100%')
      .attr('height', '100%');
    svg_nodes[key] = svg.node();
  });

if (Object.keys(svg_nodes).length > 0) {
  var database = {
    "candidate_csv": "",
    "candidate_county_csv": "",
    "candidate_state_csv": ""
  };
  var body = d3.select('body');
  var tooltip = body.append('div')
    .attr('class', 'race-tooltip');
  var tooltip_title = tooltip.append('h5');
  var tooltip_tbody = tooltip
    .append('table')
    .append('tbody');
  var hover_path = null;

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
    // ... plus we adjust the rotation and lines of latitude.

    if (features.length == 0) return null;

    var feature_collection = { type: 'FeatureCollection', features: features };
    var projection;

    if (Math.floor(features[0].id / 1000) == 2) {
      // EPSG:3338, as per http://bl.ocks.org/mbostock/5952814
      projection = d3.geo.albers()
        .rotate([ 154, 0 ])
        .center([ 0, 62 ])
        .parallels([ 55, 65 ]);
    } else {
      var ll_bounds = d3.geo.path()
        .projection(null)
        .bounds(feature_collection);
      var lon = (ll_bounds[0][0] + ll_bounds[1][0]) / 2;
      var lat = (ll_bounds[0][1] + ll_bounds[1][1]) / 2;
      // parallels at 1/6 and 5/6: http://www.georeference.org/doc/albers_conical_equal_area.htm
      var lats = [
        ll_bounds[0][1] + 5/6 * (ll_bounds[1][1] - ll_bounds[0][1]),
        ll_bounds[0][1] + 1/6 * (ll_bounds[1][1] - ll_bounds[0][1])
      ];

      projection = d3.geo.albers()
        .rotate([ -lon, 0 ])
        .center([ 0, lat ])
        .parallels(lats)
    }

    projection
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

  // Given a state-level <table> of candidates, returns [ { id: id, name: name } ]
  function extract_candidate_list(table_node) {
    var ret = [];
    d3.select(table_node).select('tbody').selectAll('tr').each(function() {
      ret.push({
        id: this.getAttribute('data-candidate-id'),
        name: d3.select(this).select('td.candidate').text(),
        nVotes: 0 // we'll overwrite this
      });
    });
    return ret;
  }

  function position_tooltip() {
    tooltip
      .classed('show', true)
      .style({ left: (10 + d3.event.pageX) + 'px', top: (10 + d3.event.pageY) + 'px' })
      ;
  }

  function show_tooltip(feature) {
    var path_node = d3.event.target;

    var svg = path_node.parentNode;

    hover_path = d3.select(svg).append('path')
      .attr('pointer-events', 'none')
      .attr('class', 'hover')
      .attr('d', path_node.getAttribute('d'))
      ;

    var party_id = svg.parentNode.getAttribute('data-party-id');
    var state_code = svg.parentNode.getAttribute('data-state-code');
    var county_id = feature.id;
    var candidates = extract_candidate_list(svg.parentNode.nextElementSibling);
    var candidates = extract_candidate_list(svg.parentNode.nextElementSibling);
    var candidates_regex = candidates.map(function(c) { return c.id; }).join('|');

    var id_to_candidate = {};
    candidates.forEach(function(c) { id_to_candidate[c.id] = c; });

    var regex = new RegExp('^(' + candidates_regex + '),' + county_id + ',(.*)$', 'gm');
    var match;
    while ((match = regex.exec(database.candidate_county_csv)) !== null) {
      var candidate_id = match[1];
      var n_votes = parseInt(match[2], 10);
      id_to_candidate[candidate_id].nVotes = n_votes;
    }

    var columns = [
      { class_name: 'name', property: 'name' },
      { class_name: 'n-votes', property: 'nVotes' }
    ];

    tooltip_tbody.data([]);
    tooltip_tbody.selectAll('tr').remove();
    tooltip_tbody.selectAll('tr')
      .data(candidates)
      .enter()
        .append('tr')
        .selectAll('td')
          .data(function(row) {
            return columns.map(function(c) { return { row: row, column: c }; });
          })
          .enter()
            .append('td')
            .attr('class', function(d) { return d.column.class_name; })
            .text(function(d) { return d.row[d.column.property]; })
      ;

    position_tooltip();
  }

  function hide_tooltip() {
    hover_path.remove();
    d3.select(d3.event.target).classed('hover', false);
    tooltip.classed('show', false);
  }

  function build_maps(us) {
    Object.keys(svg_nodes).forEach(function(key) {
      var arr = key.split('-');
      var party_id = arr[0];
      var state_code = arr[1];
      var state = StatesByCode[state_code];
      var node = svg_nodes[key];
      var svg = d3.select(node);
      var county_features = topojson.feature(us, us.objects.counties).features
        .filter(function(d) { return Math.floor(d.id / 1000) == state.fipsInt; });

      wait_for_svg_to_have_size_then(svg, function(width, height) {
        var projection = compute_projection(county_features, width, height);

        var path = d3.geo.path()
          .projection(projection);

        svg.selectAll('path')
          .data(county_features)
          .enter().append('path')
            .attr('class', 'county')
            .attr('id', function(d) { return d.id; })
            .attr('d', path)
            .on('mouseenter', show_tooltip)
            .on('mousemove', position_tooltip)
            .on('mouseleave', hide_tooltip)
            ;
      });
    });
  }

  d3.json('/2016/topojson/us.json', function(err, us) {
    if (err) throw err;

    build_maps(us);
  });

  function update_race_tables_from_database() {
    var key_to_elems = {}; // state_code-candidate_id -> { nVotes, nDelegates }, d3 elements

    d3.selectAll('table.race').each(function() {
      var table_node = this;

      var state_code = table_node.getAttribute('data-state-code');

      d3.select(table_node).select('tbody').selectAll('tr').each(function() {
        var tr = this;

        var candidate_id = tr.getAttribute('data-candidate-id');

        var key = state_code + '-' + candidate_id;

        key_to_elems[key] = {
          nVotes: d3.select(tr).select('.n-votes'),
          nDelegates: d3.select(tr).select('.n-delegates')
        };
      });
    });

    database.candidate_state_csv.split('\n').slice(1).forEach(function(line) {
      var arr = line.split(',');
      var candidate_id = arr[0];
      var state_code = arr[1];
      var n_votes = arr[2];
      var n_delegates = arr[3];

      var key = state_code + '-' + candidate_id;
      var elems = key_to_elems[key];
      if (elems) {
        elems.nVotes.text(n_votes);
        elems.nDelegates.text(n_delegates);
      }
    });
  }

  function update_race_precincts_from_database() {
    var key_to_elems = {}; // state_code-candidate_id -> { nReporting, nTotal }, d3 elements

    d3.selectAll('p.race-precincts-reporting').each(function() {
      var p = d3.select(this);

      var party_id = p.attr('data-party-id');
      var state_code = p.attr('data-state-code');
      var key = party_id + '-' + state_code;

      key_to_elems[key] = {
        nReporting: p.select('.n-reporting'),
        nTotal: p.select('.n-total'),
        lastUpdated: d3.select(p.node().nextElementSibling).select('time')
      };
    });

    database.race_csv.split('\n').slice(1).forEach(function(line) {
      var arr = line.split(',');
      var party_id = arr[0];
      var state_code = arr[1];
      var n_reporting = arr[2];
      var n_total = arr[3];
      var last_updated = new Date(arr[4]);

      var key = party_id + '-' + state_code;

      var elems = key_to_elems[key];
      if (elems) {
        elems.nReporting.text(n_reporting);
        elems.nTotal.text(n_total);
        elems.lastUpdated.text(last_updated.toISOString());
      }
    });
  }

  function endlessly_poll_for_new_database() {
    d3.json('/2016/primaries/results.json', function(err, json) {
      if (err) {
        console.log(err);
      } else {
        database = json;
        update_race_tables_from_database();
        update_race_precincts_from_database();
      }
      window.setTimeout(endlessly_poll_for_new_database, 30000);
    });
  }

  endlessly_poll_for_new_database();
}
