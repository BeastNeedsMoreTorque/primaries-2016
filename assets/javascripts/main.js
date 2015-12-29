//= require './vendor/d3.v3.js'
//= require './vendor/topojson.v1.js'
//= require './vendor/jquery-2.1.4.js'
//
//= require './states.js'

function onClickState(stateFeature) {
  var state = StatesByFipsInt[stateFeature.id];
  window.location = window.location + "/" + state.code;
}

function load_us_map() {
  // started with http://bl.ocks.org/mbostock/4090848/
  var width = 960, height = 500;

  var projection = d3.geo.albersUsa()
    .scale(1000)
    .translate([ width / 2, height / 2 ]);

  var path = d3.geo.path()
    .projection(projection);

  var svg = d3.select('#main-map')
    .attr('width', width)
    .attr('height', height);

  d3.json('/2016/topojson/us.json', function(err, us) {
    if (err) throw err;

    var stateFeatures = topojson.feature(us, us.objects.states).features;

    var states = svg.append('g').attr('class', 'states');

    states.selectAll('path')
      .data(stateFeatures)
      .enter().append('path')
        .attr('class', 'state')
        .attr('d', path)
        .on('click', onClickState)
        ;

    var labels = svg.append('g').attr('class', 'labels');

    var smallStateFipsInts = [ 'NH', 'VT', 'MA', 'RI', 'CT', 'NJ', 'DE', 'MD', 'DC' ]
      .map(function(code) { return StatesByCode[code].fipsInt; });

    var smallStateLabelStart = [ 840, 130 ];
    var smallStateLabelLeading = 24;
    var fontSize = 12; // px

    var drawProperties = [];
    stateFeatures.forEach(function(d) {
      var state = StatesByFipsInt[d.id];
      var centroid = path.centroid(d);
      if (isNaN(centroid[0])) centroid = [ -100, -100 ];

      var textStart = null;
      var smallIndex = [ 'NH', 'VT', 'MA', 'RI', 'CT', 'NJ', 'DE', 'MD', 'DC' ].indexOf(state.code);
      if (smallIndex != -1) {
        textStart = [
          smallStateLabelStart[0],
          smallStateLabelStart[1] + smallStateLabelLeading * smallIndex
        ];
      }

      if (state.code == 'FL') { centroid[0] += 10; }
      if (state.code == 'LA') { centroid[0] -= 7; }
      if (state.code == 'MI') { centroid[0] += 13; centroid[1] += 20; }
      if (state.code == 'MN') { centroid[0] -= 4; }
      if (state.code == 'WV') { centroid[0] -= 2; }

      drawProperties[d.id] = {
        centroid: centroid,
        textStart: textStart, // if different from centroid
        text: state.abbreviation
      };
    });

    labels.selectAll('line')
      .data(stateFeatures.filter(function(d) { return drawProperties[d.id].textStart !== null; }))
      .enter().append('line')
        .attr('x1', function(d) { return drawProperties[d.id].centroid[0]; })
        .attr('y1', function(d) { return drawProperties[d.id].centroid[1]; })
        .attr('x2', function(d) { return drawProperties[d.id].textStart[0] - 5; })
        .attr('y2', function(d) { return drawProperties[d.id].textStart[1]; })
        ;

    labels.selectAll('text')
      .data(stateFeatures)
      .enter().append('text')
        .attr('font-size', fontSize + 'px')
        .attr('x', function(d) { var t = drawProperties[d.id]; return (t.textStart || t.centroid)[0]; })
        .attr('y', function(d) { var t = drawProperties[d.id]; return (t.textStart || t.centroid)[1] + Math.round(fontSize * 0.4); })
        .attr('class', function(d) { return drawProperties[d.id].textStart ? 'aside' : 'in-state'; })
        .text(function(d) { return drawProperties[d.id].text; })
        .on('click', onClickState)
        ;
  });
}

$(function() {
  load_us_map();
});
