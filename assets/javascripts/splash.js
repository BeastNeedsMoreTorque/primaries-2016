$(function() {
  function add_no_results_yet_pattern_to_svg(svg, pattern_id) {
    var ns = 'http://www.w3.org/2000/svg';

    var defs = document.createElementNS(ns, 'defs');

    var pattern = document.createElementNS(ns, 'pattern');
    pattern.setAttributeNS(null, 'id', pattern_id);
    pattern.setAttributeNS(null, 'width', '50');
    pattern.setAttributeNS(null, 'height', '50');
    pattern.setAttributeNS(null, 'patternUnits', 'userSpaceOnUse');

    var rect = document.createElementNS(ns, 'rect');
    rect.setAttributeNS(null, 'width', '50');
    rect.setAttributeNS(null, 'height', '50');
    rect.setAttributeNS(null, 'fill', '#ddd');

    var path = document.createElementNS(ns, 'path');
    path.setAttributeNS(null, 'd', 'M-5,5L5,-5M-5,55L55,-5M45,55L55,45');
    path.setAttributeNS(null, 'stroke-width', '10');
    path.setAttributeNS(null, 'stroke', '#fff');

    pattern.appendChild(rect);
    pattern.appendChild(path);
    defs.appendChild(pattern);
    svg.insertBefore(defs, svg.firstChild);
  }

  function fillSvg(data){
    var pattern_id = 'progress-map-pattern-no-results';
    $('.map svg').each(function() {
      add_no_results_yet_pattern_to_svg(this, pattern_id);
    });

    $(".map svg .subcounties").children().each(function(ele){
      fips = this.getAttribute("data-geo-id");
      obj = data[fips];
      var $ele = $(".map svg .subcounties *[data-geo-id='"+ fips +"'");
      if(obj && obj['n_precincts_reporting'] == 0){
        $ele.css({fill: "url(#progress-map-pattern-no-results)"})
      }else if(obj && obj['n_precincts_reporting'] > 0 && obj['n_precincts_reporting'] < obj['n_precincts_total']) {
        $ele.css({fill: "#ddd"});
      }else if(obj && obj['n_precincts_reporting'] == obj['n_precincts_total']){
        $ele.css({fill: "#999"});
      }else{
        $ele.css({fill: "url(#progress-map-pattern-no-results)"})
        console.log('undefined result', fips, obj)
      }
    });

    var pattern_id = 'progress-map-pattern-no-results';
    $('.map.progress svg').each(function() {
      add_no_results_yet_pattern_to_svg(this, pattern_id);
    });

  }

  function updateCandidates(data, tense){
    $(".leader").removeClass("leader");

    for (key in data) {
      var candidates = data[key];
      if (candidates[0] && candidates[0].n_votes) {
        $(".candidate[data-candidate-id="+candidates[0].id+"]").addClass("leader");
      }

      for (candidate_id in data[key]) {
        var n_votes = data[key][candidate_id].votes;
        $(".candidate[data-candidate-id="+candidate_id+"] .n-votes").text(format_int(n_votes || 0));
      }
    }
  }

  function getData(){
    $.getJSON('/2016/primaries/widget-results.json', function(json) {
      var tense = json["when_race_day_happens"];
      $("body").removeClass().addClass("race-day-" + tense);
     

      fillSvg(json["geos"]);

      //updateCandidates(json["candidates"], tense);
    })
    .fail(function() { console.warn('Failed to load', this); })
    .always(function() { window.setTimeout(getData, 30000); });
  }

  //$("svg").position_svg_cities();
  $("svg .subcounties path").addClass("no-results")
  getData();
});
