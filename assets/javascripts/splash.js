$(function() {
  function update_svg_from_json($race, race_json) {
    var leader = race_json.candidates[0];
    var leader_id = leader.id;

    $race.find('.map-container .legend span.name').text(leader.last_name);

    var $svg = $race.find('svg');
    var geos = race_json.geos;

    $svg.find('g.counties path, g.subcounties path').each(function() {
      var geo_id = this.hasAttribute('data-fips-int') ? this.getAttribute('data-fips-int') : this.getAttribute('data-geo-id');
      var geo_leader_id = geos[geo_id];

      var class_name;

      if (!geo_leader_id) {
        class_name = 'no-results';
      } else if (geo_leader_id == leader_id) {
        class_name = 'candidate-leads';
      } else {
        class_name = 'candidate-trails';
      }

      this.setAttribute('class', class_name);
    });
  }

  function update_candidates_from_json($race, candidates_json) {
    var table_arr = [ '<table><tbody>' ];

    var tr_strings = candidates_json.slice(0, 3).map(function(candidate_json) {
      return '<tr class="candidate ' + (candidate_json.leader ? 'leader' : '') + ' ' + (candidate_json.winner ? 'winner' : '') + '">'
        + '<td class="candidate-name">' + candidate_json.last_name + '</td>'
        + '<td class="n-votes">' + format_int(candidate_json.n_votes || 0) + '</td>'
        + '<td class="n-votes-pct">' + format_percent(candidate_json.percent_vote || 0) + '%</td>'
        + '</tr>';
    });

    $race.find('.candidate-position-listing').html('<table><tbody>' + tr_strings.join('') + '</tbody></table>');
  }

  function update_precincts_reporting_from_json($race, string) {
    $race.find('.precincts-val').text(string);
    $race
      .toggleClass('no-precincts-reporting', string == 'N/A')
      .toggleClass('precincts-reporting', string != 'N/A');
  }

  function update_when_race_happens_from_json($race, tense) {
    $race
      .removeClass('race-past race-present race-future')
      .addClass('race-' + tense);
  }

  function update_race_from_json(race_json) {
    var $race = $('#' + race_json.id);

    update_when_race_happens_from_json($race, race_json.when_race_happens);
    update_svg_from_json($race, race_json);
    update_candidates_from_json($race, race_json.candidates);
    update_precincts_reporting_from_json($race, race_json.precincts_reporting_percent_s);
  }

  function do_poll(callback) {
    $.getJSON('/2016/primaries/widget-results.json', function(json) {
      var tense = json.when_race_day_happens;
      $("body").removeClass('race-day-past race-day-present race-day-future').addClass("race-day-" + tense);

      json.races.forEach(update_race_from_json);
    })
      .fail(function() { console.warn('Failed to load', this); })
      .always(callback);
  }

  $("svg").position_svg_cities();

  $('button.refresh')
    .countdown(30, do_poll)
    .trigger('click.countdown'); // poll immediately on page load, to populate map; don't trigger AOL beacon
});
