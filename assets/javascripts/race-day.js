var database = {
  candidate_csv: "",
  candidate_county_race_csv: "",
  candidate_race_subcounty_csv: "",
  candidate_race_csv: "",
  county_race_csv: "",
  race_csv: ""
};
var on_database_change = []; // Array of zero-argument callbacks

function n_precincts_text(n) {
  return n == 1 ? '1 precinct' : (n + ' precincts');
}

function n_precincts_reporting_text(reporting, total) {
  if (total == 0) {
    return 'There are no precincts here';
  } else {
    return reporting + ' of ' + n_precincts_text(total) + ' reporting (' + Math.round(100 * reporting / total) + '%)';
  }
}

/**
 * Returns a list of { id, name, n_votes } from a <table class="candidates">.
 */
function extract_candidate_list($party_state_table) {
  var ret = [];

  $party_state_table.find('tr[data-candidate-id]').each(function() {
    ret.push({
      id: this.getAttribute('data-candidate-id'),
      name: $('td.candidate span.name', this).text(),
      highlighted: $(this).hasClass('highlight-on-map'),
      n_votes: 0 // we'll overwrite this
    });
  });

  return ret;
}

function add_tooltips() {
  // One $tooltip for all <svg>s
  var $tooltip = $('<div class="race-tooltip">' +
    '<div class="tooltip-contents">' +
      '<a class="close">×</a>' +
      '<h4></h4>' +
      '<table>' +
        '<thead>' +
          '<tr>' +
            '<th class="candidate">Candidate</th>' +
            '<th class="n-votes">Votes</th>' +
            '<th class="n-votes n-state-delegate-equivalents"><abbr title="State Delegate Equivalents">SDEs</abbr>×100<sup>∗</sup></th>' +
            '<th class="percent-vote">%</th>' +
          '</tr>' +
        '</thead>' +
        '<tbody></tbody>' +
      '</table>' +
      '<p class="n-state-delegate-equivalents"><sup>∗</sup> The Iowa Democratic Party reports State Delegate Equivalents (SDEs), not votes.</p>' +
      '<p class="precincts"></p>' +
    '</div></div>');
  var svg_hover_path = null;

  function update_tooltip(county_name, candidates, n_votes_in_county, n_reporting, n_total, is_from_touch) {
    $tooltip.find('h4').text(county_name);

    if (n_total) {
      $tooltip.find('table').show();
      $tooltip.find('span.n-reporting').text(format_int(n_reporting));
      $tooltip.find('span.n-total').text(format_int(n_total));
      $tooltip.find('p.precincts').text(n_precincts_reporting_text(n_reporting, n_total)).removeClass('no-precincts-note');
      $tooltip.toggleClass('opened-from-touch', is_from_touch);

      var $tbody = $tooltip.find('tbody').empty();

      candidates
        .sort(function(a, b) { return b.n_votes - a.n_votes || a.name.localeCompare(b.name); })
        .forEach(function(candidate) {
          $tr = $('<tr><td class="candidate"></td><td class="n-votes"></td><td class="percent-vote"></td></tr>')
            .toggleClass('highlight-on-map', candidate.highlighted);
          $tr.find('.candidate').text(candidate.name);
          $tr.find('.n-votes').text(format_int(candidate.n_votes));
          $tr.find('.percent-vote').text(n_votes_in_county ? format_percent(100 * candidate.n_votes / n_votes_in_county) : 0);
          $tbody.append($tr);
        });
    } else {
      $tooltip.find('table').hide();
      $tooltip.find('p.precincts').text('No polling places').addClass('no-precincts-note');
    }
  }

  function position_tooltip_near_svg_path(svg_path) {
    // Remember: getBoundingClientRect() returns *viewport* coordinates.
    var margin = 10; // px
    var path_rect = svg_path.getBoundingClientRect();

    var body_width = $('body').width();
    var $div = $(svg_path).closest('div'); // has position: relative

    $div.append($tooltip);
    var div_rect = $div[0].getBoundingClientRect();
    var tooltip_rect = $tooltip[0].getBoundingClientRect();

    // x: make it center the tooltip with the center of the state, respecting
    // the bounds of the page.
    var cx = Math.round(path_rect.left - div_rect.left + path_rect.width / 2);
    var x = cx - $tooltip.width() / 2;

    if (div_rect.left + x < 0) x = -div_rect.left;
    if (div_rect.left + x + tooltip_rect.width > body_width) x = body_width - tooltip_rect.width - div_rect.left;

    // y: if the tooltip fits above, show it above. Otherwise, show it below.
    var y;
    if (path_rect.top - tooltip_rect.height - margin >= 0) {
      y = Math.round(path_rect.top - div_rect.top - tooltip_rect.height - margin); // above
    } else {
      y = Math.round(path_rect.bottom - div_rect.top + margin);
    }

    $tooltip.css({ left: x + 'px', top: y + 'px' });
  }

  function remove_tooltip() {
    $tooltip.remove();
  }

  function find_geo_data_from_csvs(geo_id, race_key, geo_race_csv, candidate_geo_race_csv, candidates) {
    var id_to_candidate = {};
    candidates.forEach(function(c) { id_to_candidate[c.id] = c; });

    var candidates_regex = candidates.map(function(c) { return c.id; }).join('|');
    var regex = new RegExp('^(' + candidates_regex + '),' + geo_id + ',(.*)$', 'gm');
    var match;
    while ((match = regex.exec(candidate_geo_race_csv)) !== null) {
      var candidate_id = match[1];
      var n_votes = parseInt(match[2], 10);
      id_to_candidate[candidate_id].n_votes = n_votes;
    }

    var meta_regex = new RegExp('^' + race_key + ',(.*)$', 'm');
    if ((match = meta_regex.exec(geo_race_csv)) !== null) {
      var match_arr = match[1].split(',');

      return {
        n_votes: +match_arr[0],
        n_reporting: +match_arr[1],
        n_total: +match_arr[2]
      };
    } else {
      return null;
    }
  }

  function find_county_data_for_fips_int(fips_int, party_id, candidates) {
    return find_geo_data_from_csvs(
      fips_int,
      fips_int + ',' + party_id,
      database.county_race_csv,
      database.candidate_county_race_csv,
      candidates
    );
  }

  function find_subcounty_data_for_geo_id(geo_id, party_id, candidates) {
    return find_geo_data_from_csvs(
      geo_id,
      party_id + ',' + geo_id,
      database.race_subcounty_csv,
      database.candidate_race_subcounty_csv,
      candidates
    );
  }

  function show_tooltip_for_svg_path(svg_path, is_from_touch) {
    var geo_name = svg_path.getAttribute('data-name');
    var party_id = $(svg_path).closest('[data-party-id]').attr('data-party-id');
    var state_code = $(svg_path).closest('[data-state-code]').attr('data-state-code');
    var candidates = extract_candidate_list($(svg_path).closest('.party-state').find('table.candidates'));

    var data;

    if (svg_path.hasAttribute('data-fips-int')) {
      data = find_county_data_for_fips_int(svg_path.getAttribute('data-fips-int'), party_id, candidates);
    } else {
      data = find_subcounty_data_for_geo_id(svg_path.getAttribute('data-geo-id'), party_id, candidates);
    }

    if (data) {
      update_tooltip(geo_name, candidates, data.n_votes, data.n_reporting, data.n_total, is_from_touch);
      $tooltip.toggleClass('is-state-delegate-equivalents', party_id == 'Dem' && state_code == 'IA');
      position_tooltip_near_svg_path(svg_path);
    } else {
      update_tooltip(geo_name);
      $tooltip.toggleClass('is-state-delegate-equivalents', party_id == 'Dem' && state_code == 'IA');
      position_tooltip_near_svg_path(svg_path);
    }
  }

  function add_hover_path(svg_path) {
    if (svg_hover_path) throw new Error('There is already a hover path');

    var g = svg_path.parentNode;
    var svg = g.parentNode;
    svg_hover_path = svg_path.cloneNode();
    svg_hover_path.setAttribute('transform', g.getAttribute('transform'));
    svg_hover_path.setAttribute('class', 'hover');
    svg.insertBefore(svg_hover_path, svg.lastChild.previousSibling); // before <g class="cities">
  }

  function remove_hover_path() {
    if (svg_hover_path === null) return; // Sometimes happens when leaving page
    svg_hover_path.parentNode.removeChild(svg_hover_path);
    svg_hover_path = null;
  }

  var last_touchend_date = null;

  function on_touchend() {
    last_touchend_date = new Date();
  }

  function on_mouseenter(ev) {
    var svg_path = this;
    add_hover_path(svg_path);

    /*
     * mouseenter also happens when the user touches something. That's good: we
     * want to show the tooltip in that case. We need to add a close button, or
     * the user won't know how to remove the tooltip.
     *
     * We don't *actually* need to detect that this specific mouseenter was
     * from touch -- that's hard. Instead, we detect a superset: show the close
     * button if the user has touched something in the past second.
     */
    var user_uses_touch = !!last_touchend_date && new Date() - last_touchend_date < 1000;

    show_tooltip_for_svg_path(svg_path, user_uses_touch);
  }

  function on_mouseleave() {
    remove_hover_path();
    remove_tooltip(); // before the user can even click the button :)
  }

  function add_tooltip(svg) {
    $(svg)
      .on('mouseenter', 'g.counties path, g.subcounties path', on_mouseenter)
      .on('mouseleave', 'g.counties path, g.subcounties path', on_mouseleave);
  }

  $(document).on('touchend', on_touchend);

  /*
   * On Android, you can't click the "close" button on the tooltip: you'll
   * trigger 'mouseleave' first on the path that it represents, which will
   * close it.
   *
   * On iPhone, the 'mouseleave' doesn't happen. So we need to wire up the
   * button, because users can actually click it.
   */
  $(document).on('click', '.race-tooltip a.close', on_mouseleave);

  $('.party-state-map svg').each(function() {
    add_tooltip(this);
  });
}

function color_counties() {
  var geo_results = null; // party_id -> geo_id -> { candidate_id_to_n_votes, leader_n_votes, all_precincts_reporting (Boolean) }
  var races_with_results = {}; // "#{party_id}-#{state_code}" -> null

  /**
   * Builds an Object mapping candidate_id to party_id, from
   * database.candidate_csv
   */
  function build_candidate_id_to_party_id() {
    var ret = {};

    var regex = new RegExp('^(\\d+),(\\w{3})', 'gm');
    var match;
    while ((match = regex.exec(database.candidate_csv)) !== null) {
      var candidate_id = match[1];
      var party_id = match[2];
      ret[candidate_id] = party_id;
    }

    return ret;
  }

  function refresh_geo_results() {
    geo_results = {};

    var candidate_id_to_party_id = build_candidate_id_to_party_id(); // candidate_id -> party_id

    function add_geo_match(match, county_or_subcounty) {
      var party_id = match[county_or_subcounty == 'subcounty' ? 1 : 2];
      var geo_id = +match[county_or_subcounty == 'subcounty' ? 2 : 1];
      var n_precincts_reporting = +match[4];
      var n_precincts_total = +match[5];

      if (!geo_results[party_id]) geo_results[party_id] = {};
      geo_results[party_id][geo_id] = {
        candidate_id_to_n_votes: {},
        all_precincts_reporting: (n_precincts_reporting == n_precincts_total),
        leader_n_votes: 0
      };
    }

    function maybe_add_candidate_geo_match(match) {
      var candidate_id = match[1];
      var party_id = candidate_id_to_party_id[candidate_id];
      if (!party_id) return;

      var geo_id = +match[2];
      var n_votes = +match[3];

      var counts = geo_results[party_id][geo_id];
      counts.candidate_id_to_n_votes[candidate_id] = n_votes;

      if (n_votes > counts.leader_n_votes) {
        counts.leader_n_votes = n_votes;
      }
    }

    var regex = new RegExp('^(\\d+),(Dem|GOP),(\\d+),(\\d+),(\\d+)$', 'gm');
    var match;

    while ((match = regex.exec(database.county_race_csv)) != null) {
      add_geo_match(match, 'county');
    }

    regex = new RegExp('^(Dem|GOP),(\\d+),(\\d+),(\\d+),(\\d+)$', 'gm'); // reset
    while ((match = regex.exec(database.race_subcounty_csv)) != null) {
      add_geo_match(match, 'subcounty');
    }

    regex = new RegExp('^(\\d+),(\\d+),(\\d+)$', 'gm');
    while ((match = regex.exec(database.candidate_county_race_csv)) !== null) {
      maybe_add_candidate_geo_match(match);
    }

    regex = new RegExp('^(\\d+),(\\d+),(\\d+)$', 'gm'); // reset
    while ((match = regex.exec(database.candidate_race_subcounty_csv)) !== null) {
      maybe_add_candidate_geo_match(match);
    }
  }
  on_database_change.push(refresh_geo_results);

  function refresh_races_with_results() {
    races_with_results = {};

    var regex = new RegExp('^(\\w+),(\\w+),(\\d+)', 'gm');
    var match;
    while ((match = regex.exec(database.race_csv)) !== null) {
      if (match[3] != '0') {
        var party_id = match[1];
        var state_code = match[2];
        var key = party_id + '-' + state_code;
        races_with_results[key] = null;
      }
    }
  }
  on_database_change.push(refresh_races_with_results);

  /**
   * Returns a className for an svg <path>, from geo_results.
   *
   * @param party_id String party ID.
   * @param geo_id String county fips_int or subcounty geo_id.
   * @param candidate_id String candidate ID.
   * @return One of 'candidate-wins', 'candidate-leads', 'candidate-trails', 'candidate-loses', 'no-results'.
   */
  function lookup_candidate_class(party_id, geo_id, candidate_id) {
    if (!geo_results[party_id] || !geo_results[party_id][geo_id] || !geo_results[party_id][geo_id].leader_n_votes) {
      return 'no-results';
    } else {
      var counts = geo_results[party_id][geo_id];
      var n_votes = counts.candidate_id_to_n_votes[candidate_id];
      if (n_votes == counts.leader_n_votes) {
        if (counts.all_precincts_reporting) {
          return 'candidate-wins';
        } else {
          return 'candidate-leads';
        }
      } else {
        if (counts.all_precincts_reporting) {
          return 'candidate-loses';
        } else {
          return 'candidate-trails';
        }
      }
    }
  }

  /**
   * Returns a Boolean indicating whether any precincts are reporting, from
   * `races_with_results`.
   */
  function race_has_results(party_id, state_code) {
    var key = party_id + '-' + state_code;
    return races_with_results.hasOwnProperty(key);
  }

  function refresh_svg_legend(svg, table) {
    var $legend = $(svg.nextElementSibling);
    var candidate_name = $('tbody tr.highlight-on-map td.candidate span.name', table).text();

    [ 'no-results', 'candidate-wins', 'candidate-leads', 'candidate-trails', 'candidate-loses' ].forEach(function(klass) {
      $legend.toggleClass('has-' + klass, $('path.' + klass, svg).length > 0);
    });
    $legend.find('.candidate-name').text(candidate_name || '');
  }

  function refresh_svg_classes(svg, table, party_id, state_code) {
    var $candidate_tr = $(table).find('tbody tr.highlight-on-map');
    if ($candidate_tr.length == 0) {
      $candidate_tr = $(table).find('tbody tr:first');
      $candidate_tr.addClass('highlight-on-map');
    }

    var candidate_id = $candidate_tr.attr('data-candidate-id');
    var pattern_id_start = 'pattern-' + party_id + '-' + state_code + '-';

    $(svg).find('g.counties path:not(.hover), g.subcounties path:not(.hover)').each(function() {
      var geo_id = this.getAttribute('data-fips-int') || this.getAttribute('data-geo-id');
      var class_name = lookup_candidate_class(party_id, geo_id, candidate_id);
      this.setAttribute('class', class_name);

      if (class_name == 'candidate-leads' || class_name == 'candidate-trails') {
        this.setAttribute('style', 'fill: url(#' + pattern_id_start + class_name + ')');
      } else {
        this.setAttribute('style', '');
      }
    });
  }

  /**
   * Adds <pattern id="pattern-Dem-NH-candidate-leads"> (and
   * id="pattern-Dem-NH-candidate-trails">).
   *
   * The pattern, when set through `style: fill(#[pattern_id])`, will indicate
   * that there are no results yet for the given county.
   *
   * Why not put the <pattern> in the SVG? Because the same <svg> goes twice
   * into a single race-day <html>, and it needs an `id` attribute. We can't use
   * the same `id` attribute in two places.
   *
   * Why not put the `style` in CSS? Because it needs to use a fragment
   * identifier (that's the `#` part of
   * `fill: url(#pattern-Dem-NH-candidate-leads)`). Firefox would (correctly)
   * look for `#pattern-Dem-NH-candidate-leads` in the CSS file, but it isn't
   * in the CSS. In other words, CSS and SVG don't work together the way you'd
   * expect.
   *
   * Why do we include "Dem-NH" in the ID? Because the ID needs to be unique
   * across the entire page.
   */
  function add_patterns_to_svg(svg) {
    var ns = 'http://www.w3.org/2000/svg';

    var $race = $(svg).closest('.race');
    var party_id = $race.attr('data-party-id');
    var state_code = $race.attr('data-state-code');
    var leads_color = party_id == 'Dem' ? '#5c6b95' : '#bc5c5c'; // $strongDem, $strongGOP from _variables.scss
    var trails_color = '#ddd'; // $undecided from _variables.scss

    function buildPattern(id_fragment, color) {
      var pattern = document.createElementNS(ns, 'pattern');
      pattern.setAttributeNS(null, 'id', 'pattern-' + party_id + '-' + state_code + '-' + id_fragment);
      pattern.setAttributeNS(null, 'width', '50');
      pattern.setAttributeNS(null, 'height', '50');
      pattern.setAttributeNS(null, 'patternUnits', 'userSpaceOnUse');

      var rect = document.createElementNS(ns, 'rect');
      rect.setAttributeNS(null, 'width', '50');
      rect.setAttributeNS(null, 'height', '50');
      rect.setAttributeNS(null, 'fill', color);

      var path = document.createElementNS(ns, 'path');
      path.setAttributeNS(null, 'd', 'M-5,5L5,-5M-5,55L55,-5M45,55L55,45');
      path.setAttributeNS(null, 'stroke-width', '10');
      path.setAttributeNS(null, 'stroke', 'white');

      pattern.appendChild(rect);
      pattern.appendChild(path);

      return pattern;
    }

    var defs = document.createElementNS(ns, 'defs');

    defs.appendChild(buildPattern('candidate-leads', leads_color));
    defs.appendChild(buildPattern('candidate-trails', trails_color));

    svg.insertBefore(defs, svg.firstChild);
  }

  function monitor_svg(svg, table, party_id, state_code) {
    add_patterns_to_svg(svg);

    on_database_change.push(function() {
      if (race_has_results(party_id, state_code)) {
        refresh_svg_classes(svg, table, party_id, state_code);
        refresh_svg_legend(svg, table);
      }
    });

    var $table = $(table);
    $table.on('click', 'tbody tr', function(ev) {
      var $tr = $(ev.currentTarget);

      if (race_has_results(party_id, state_code)) {
        $table.find('tr.highlight-on-map').removeClass('highlight-on-map');
        $tr.addClass('highlight-on-map');
        refresh_svg_classes(svg, table, party_id, state_code);
        refresh_svg_legend(svg, table);
      }
    });
  }

  $('.party-state-map svg').each(function() {
    var $race = $(this).closest('.race');
    var $table = $race.find('table');
    var party_id = $race.attr('data-party-id');
    var state_code = $race.attr('data-state-code');

    monitor_svg(this, $table[0], party_id, state_code);
  });
}

function poll_results() {
  var els_by_candidate_id_and_state_code = null; // Maps "123-CA" to { n_votes, n_delegates, tr }.
  function ensure_els_by_candidate_id_and_state_code_is_populated() {
    if (els_by_candidate_id_and_state_code) return;

    var els = els_by_candidate_id_and_state_code = {};

    $('.race[data-state-code]').each(function() {
      var state_code = this.getAttribute('data-state-code');

      $('tr[data-candidate-id]', this).each(function() {
        var candidate_id = this.getAttribute('data-candidate-id');

        els[candidate_id + '-' + state_code] = {
          tr: this,
          candidate: $('td.candidate', this),
          n_votes: $('td.n-votes', this),
          percent_vote: $('td.percent-vote', this),
          n_delegates_dots: $('td.n-delegates-dots', this),
          n_delegates_int: $('td.n-delegates', this)
        };
      });
    });
  }

  var els_by_party_id_and_state_code = null;
  function ensure_els_by_party_id_and_state_code_is_populated() {
    if (els_by_party_id_and_state_code) return;

    var els = els_by_party_id_and_state_code = {};

    $('.race[data-party-id][data-state-code]').each(function() {
      var party_id = this.getAttribute('data-party-id');
      var state_code = this.getAttribute('data-state-code');

      var $ndwc = $('.n-delegates-with-candidates', this);

      var these_els = els[party_id + '-' + state_code] = {
        race: $(this),
        n_precincts: $('.race-status .n-precincts-reporting', this),
        last_updated: $('.race-status time', this),
        n_delegates_with_candidates: {
          dots: $ndwc.find('.dots', this),
          int_with_candidates: $ndwc.find('.n-delegates-with-candidates-int', this),
          int_total: $ndwc.find('.n-delegates-int', this)
        },
      };
    });
  }

  function tr_order_matches_document_order(trs_in_order) {
    // Merge sort two Arrays of <tr> elements
    var document_trs = $('table.candidates tbody tr').get();

    if (document_trs.length != trs_in_order.length) {
      return false; // should never happen; undefined behavior if it does
    }

    for (var i = 0; i < trs_in_order.length; i++) {
      var tr = trs_in_order[i];
      var dtr = document_trs[i];

      if (tr != dtr) {
        return false;
      }
    }

    return true;
  }

  function update_race_tables_from_database() {
    ensure_els_by_candidate_id_and_state_code_is_populated();

    var trs_in_order = []; // The server gives us the correct ordering.

    database.candidate_race_csv.split('\n').slice(1).forEach(function(line) {
      var arr = line.split(',');
      var candidate_id = arr[0];
      var state_code = arr[1];
      var n_votes = +arr[2];
      var percent_vote = +arr[3];
      var n_delegates = +arr[4];
      var winner = (arr[5] == 'true');

      var key = candidate_id + '-' + state_code;
      var elems = els_by_candidate_id_and_state_code[key];
      if (elems) {
        trs_in_order.push(elems.tr);
        $(elems.tr).toggleClass('winner', winner);
        elems.n_votes.text(format_int(n_votes));
        elems.percent_vote.text(format_percent(percent_vote));

        elems.n_delegates_dots.assign_simple_dot_groups(n_delegates);
        elems.n_delegates_int.text(format_int(n_delegates));
      }
    });

    if (!tr_order_matches_document_order(trs_in_order)) {
      trs_in_order.forEach(function(tr) {
        tr.parentNode.appendChild(tr);
      });
    }
  }

  function update_races_from_database() {
    ensure_els_by_party_id_and_state_code_is_populated();

    database.race_csv.split('\n').slice(1).forEach(function(line) {
      var arr = line.split(',');
      var party_id = arr[0];
      var state_code = arr[1];
      var n_reporting = +arr[2];
      var n_total = +arr[3];
      var has_delegate_counts = arr[4] == 'true';
      var last_updated = new Date(arr[5]);
      var when_race_happens = arr[6]; // 'past', 'present' or 'future'
      var n_delegates_with_candidates = +arr[7];
      var n_delegates = +arr[8];

      var key = party_id + '-' + state_code;

      var elems = els_by_party_id_and_state_code[key];
      if (elems) {
        elems.race
          .removeClass('past present future')
          .addClass(when_race_happens)
          .removeClass('no-precincts-reporting precincts-reporting')
          .addClass(n_reporting > 0 ? 'precincts-reporting' : 'no-precincts-reporting')
          .toggleClass('has-delegate-counts', has_delegate_counts);

        elems.n_precincts.text(n_precincts_reporting_text(n_reporting, n_total));
        if (!isNaN(last_updated.getFullYear())) {
          elems.last_updated.attr('datetime', last_updated.toISOString()).render_datetime();
        }
        var dels = elems.n_delegates_with_candidates;
        dels.dots.assign_bisected_dot_groups('with-candidates', n_delegates_with_candidates, 'without-candidates', n_delegates - n_delegates_with_candidates);
        dels.int_with_candidates.text(format_int(n_delegates_with_candidates));
        dels.int_total.text(format_int(n_delegates));
      }
    });
  }

  function handle_poll_results(json) {
    database = json;
    on_database_change.forEach(function(f) { f(); });
  }

  on_database_change.push(update_race_tables_from_database);
  on_database_change.push(update_races_from_database);

  function do_poll(callback) {
    var json_url = window.location.toString().split('#')[0] + '.json';

    $.getJSON(json_url, handle_poll_results)
      .fail(function() { console.warn('Failed to load ' + json_url, this); })
      .always(callback);
  }

  $('button.refresh')
    .countdown(30, do_poll)
    .click(); // poll immediately on page load
}

/**
 * Ensures that when Democratic and Republican <p class="text"> blurbs are
 * aligned, their heights are identical.
 *
 * This makes the rest of the page flow nicely.
 */
function fix_text_heights() {
  var refresh_requested = false;

  function refresh_text_heights() {
    refresh_requested = false;

    $('li.state p.text').css({ height: 'auto' });

    $('li.state').each(function() {
      var $ps = $('p.text', this);
      if ($ps.length == 2) {
        if ($ps[0].getBoundingClientRect().top == $ps[1].getBoundingClientRect().top) {
          var $p1 = $ps.first();
          var $p2 = $ps.last();
          var h = Math.max($p1.height(), $p2.height());
          $ps.css({ height: h + 'px' });
        }
      }
    });
  }

  window.addEventListener('resize', function() {
    if (!refresh_requested) {
      refresh_requested = true;
      window.requestAnimationFrame(refresh_text_heights);
    }
  });

  refresh_text_heights();
}

$(function() {
  $('body.race-day').each(function() {
    $('time').render_datetime();

    wait_for_font_then('Source Sans Pro', function() {
      fix_text_heights();
      $('.race svg').position_svg_cities();
    });

    add_tooltips();
    color_counties(); // set up on_database_change
    poll_results(); // send AJAX request
  });

  $('.dropdown-button').click(function() {
    $('.dropdown-menu').toggleClass("visible");
  });

  $(".dropdown-link").click(function() {
    $('.dropdown-menu').toggleClass("visible");
  });
});
