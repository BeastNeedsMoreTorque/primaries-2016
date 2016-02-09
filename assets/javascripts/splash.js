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

  function fillSvg(data, leaders){
    for (var fips in data) {
      var obj = data[fips];
      var $ele_gop = $(".map-container.gop .map svg .subcounties *[data-geo-id='"+ fips +"']");
      var $ele_dem = $(".map-container.dem .map svg .subcounties *[data-geo-id='"+ fips +"']");

      if(obj.GOP.leader.n_votes > 0)
        //console.log(obj, leaders.GOP)
      if(obj.GOP.leader.n_votes > 0 && obj.GOP.leader.id == leaders.GOP.id){
        $ele_gop.css({"fill": "#bc5c5c"})
      }else if(obj.GOP.leader.n_votes > 0 && obj.GOP.leader.id != leaders.GOP.id){
        $ele_gop.css({"fill": "#f5cfcf"})
      }

      if(obj.Dem.leader.n_votes > 0 && obj.Dem.leader.id == leaders.Dem.id){
        $ele_dem.css({"fill": "#5c6b95"})
      }else if(obj.Dem.leader.n_votes > 0 && obj.Dem.leader.id != leaders.Dem.id){
        $ele_dem.css({"fill": "#d1e0fa"})
      }

    }

  }

  function updateCandidates(data, tense){
    $(".party-container.gop .candidate-position-listing table").remove();
    $(".party-container.dem .candidate-position-listing table").remove();

    ["Dem", "GOP"].forEach(function(party){
      var table = "" +
                  "<table>" +
                    "<tbody>";
      data.candidates[party].forEach(function(c, i){
        var row = "" +
                  "<tr class='candidate "+ (i==0 ? 'leader' : '') +"' data-candidate-id='"+ c.id +"'>" + 
                    "<td class='candidate-name'>" + c.name + "</td>" +
                    "<td class='n-votes'>" + format_int(c.votes) + "</td>" +
                    "<td class='n-votes-pct'>" + (c.pct ? c.pct.toFixed(1) : "0.0") + "%</td>" +
                  "</tr>";
        if(i == 0)
          $(".map-container."+party.toLowerCase()+" .legend span.name").html(c.name)
        if(i < 3)
          table += row;
      });
      table += "</tbody></table>";
      $(".party-container."+party.toLowerCase()+" .candidate-position-listing").append(table);
    })
  }

  function updatePrecinctStats(data){
    [ 'dem', 'gop' ].forEach(function(party_id_lower) {
      $container = $('.map-precincts-container.' + party_id_lower);
      var str = data['reporting_precincts_pct_str_' + party_id_lower];
      var reporting = str != 'N/A';

      $container.find('.precincts-val').text(str);
      $container
        .toggleClass('no-precincts-reporting', !reporting)
        .toggleClass('precincts-reporting', reporting);
    });
  }

  function do_poll(callback) {
    $.getJSON('/2016/primaries/widget-results.json', function(json) {
      var tense = json["when_race_day_happens"];

      $("body").removeClass('race-day-past race-day-present race-day-future').addClass("race-day-" + tense);

      fillSvg(json.geos, json.candidates.leaders);

      updateCandidates(json.candidates);
      updatePrecinctStats(json.precincts);
    })
      .fail(function() { console.warn('Failed to load', this); })
      .always(callback);
  }

  $("svg").position_svg_cities();

  $('button.refresh')
    .countdown(30, do_poll)
    .click(); // start right away
});
