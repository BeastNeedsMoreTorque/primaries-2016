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

  function fillSvg(data, leaders) {
    var colors = {
      Dem: { lead: '#5c6b95', trail: '#d1e0fa' },
      GOP: { lead: '#bc5c5c', trail: '#f5cfcf' }
    };

    [ 'Dem', 'GOP' ].forEach(function(party_id) {
      var party_id_lower = party_id.toLowerCase();
      var $svg = $('.map-container.' + party_id_lower + ' svg');

      $svg.find('g.counties path, g.subcounties path').each(function() {
        var geo_id = this.hasAttribute('data-fips-int') ? this.getAttribute('data-fips-int') : this.getAttribute('data-geo-id');
        var geo_leader = data[geo_id] ? data[geo_id][party_id].leader : null;

        if (geo_leader == null) return;

        if (geo_leader.n_votes > 0) {
          // Some precincts are reporting. Color the map. (It will never become
          // uncolored after this.)

          var leader = leaders[party_id];

          if (geo_leader.id == leader.id) {
            this.setAttribute('fill', colors[party_id].lead);
          } else {
            this.setAttribute('fill', colors[party_id].trail);
          }
        }
      });
    });
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
                  "<tr class='candidate "+ (i==0 ? 'leader' : '') + ' ' + (c.winner ? 'winner' : '') + "' data-candidate-id='"+ c.id +"'>" + 
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
