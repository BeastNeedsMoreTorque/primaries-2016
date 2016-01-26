//= require ./render_time.js
//= require ./format_int.js
//= require ./ellipsize_table.js
//
//= require ./position_svg_cities.js

var database = {
  candidate_csv: "",
  candidate_county_csv: "",
  candidate_state_csv: "",
  county_party_csv: "",
  race_csv: ""
};
var on_database_change = []; // Array of zero-argument callbacks

/**
 * Returns a list of { id, name, n_votes } from a <table class="race">.
 */
function extract_candidate_list($party_state_table) {
  var ret = [];

  $party_state_table.find('tr[data-candidate-id]').each(function() {
    ret.push({
      id: this.getAttribute('data-candidate-id'),
      name: $('td.candidate', this).text(),
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
          '</tr>' +
        '</thead>' +
        '<tbody></tbody>' +
      '</table>' +
      '<p class="precincts"><span class="n-reporting">0</span> of <span class="n-total"></span> precincts reporting</p><p class="last-updated">Last updated <time></time></p></div></div>');
  var svg_hover_path = null;

  function update_tooltip(county_name, candidates, n_reporting, n_total, last_updated, is_from_touch) {
    $tooltip.find('h4').text(county_name);
    $tooltip.find('span.n-reporting').text(format_int(n_reporting));
    $tooltip.find('span.n-total').text(format_int(n_total));
    $tooltip.toggleClass('opened-from-touch', is_from_touch);
    if (last_updated) {
      $tooltip.find('.last-updated time').attr('datetime', last_updated.toISOString()).render_datetime();
    }

    var $tbody = $tooltip.find('tbody').empty();

    candidates
      .sort(function(a, b) { return b.n_votes - a.n_votes || a.name.localeCompare(b.name); })
      .forEach(function(candidate) {
        $tr = $('<tr><td class="candidate"></td><td class="n-votes"></td></tr>');
        $tr.find('.candidate').text(candidate.name);
        $tr.find('.n-votes').text(format_int(candidate.n_votes));
        $tbody.append($tr);
      });
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

  function show_tooltip_for_svg_path(svg_path, is_from_touch) {
    var county_name = svg_path.getAttribute('data-name');
    var fips_int = +svg_path.getAttribute('data-fips-int');
    var party_id = $(svg_path).closest('[data-party-id]').attr('data-party-id');
    var state_code = $(svg_path).closest('[data-state-code]').attr('data-state-code');

    var candidates = extract_candidate_list($(svg_path).closest('.party-state').find('table.race'));
    var candidates_regex = candidates.map(function(c) { return c.id; }).join('|');

    var id_to_candidate = {};
    candidates.forEach(function(c) { id_to_candidate[c.id] = c; });

    var regex = new RegExp('^(' + candidates_regex + '),' + fips_int + ',(.*)$', 'gm');
    var match;
    while ((match = regex.exec(database.candidate_county_csv)) !== null) {
      var candidate_id = match[1];
      var n_votes = parseInt(match[2], 10);
      id_to_candidate[candidate_id].n_votes = n_votes;
    }

    var meta_regex = new RegExp('^' + fips_int + ',' + party_id + ',(.*)$', 'm');
    if ((match = meta_regex.exec(database.county_party_csv)) !== null) {
      var match_arr = match[1].split(',');

      var n_reporting = +match_arr[0];
      var n_total = +match_arr[1];
      var last_updated = new Date(match_arr[2]);

      update_tooltip(county_name, candidates, n_reporting, n_total, last_updated, is_from_touch);
      position_tooltip_near_svg_path(svg_path);
    } else {
      console.warn('Could not find data for tooltip');
    }
  }

  function add_hover_path(svg_path) {
    if (svg_hover_path) throw new Error('There is already a hover path');

    var counties = svg_path.parentNode;
    svg_hover_path = svg_path.cloneNode();
    svg_hover_path.setAttribute('class', 'hover');
    counties.appendChild(svg_hover_path);
  }

  function remove_hover_path() {
    if (svg_hover_path === null) return; // Sometimes happens when leaving page
    svg_hover_path.parentNode.removeChild(svg_hover_path);
    svg_hover_path = null;
  }

  var mouseenter_was_touch = false;

  function on_touchend() {
    mouseenter_was_touch = true;
  }

  function on_mouseenter(ev) {
    var svg_path = this;
    add_hover_path(svg_path);
    show_tooltip_for_svg_path(svg_path, mouseenter_was_touch);
    mouseenter_was_touch = false; // reset
  }

  function on_mouseleave() {
    remove_hover_path();
    remove_tooltip(); // before the user can even click the button :)
    mouseenter_was_touch = false; // reset
  }


  function add_tooltip(svg) {
    $(svg)
      .on('mouseenter', 'g.counties path', on_mouseenter)
      .on('touchend', 'g.counties path', on_touchend)
      .on('mouseleave', 'g.counties path', on_mouseleave);
  }

  $('.party-state-map svg').each(function() {
    add_tooltip(this);
  });
}

function color_counties() {
  var county_results = null; // party_id -> fips_int -> { candidate_id_to_n_votes, winner_n_votes }
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

  function refresh_county_results() {
    county_results = {};

    var candidate_id_to_party_id = build_candidate_id_to_party_id(); // candidate_id -> party_id

    var regex = new RegExp('^(\\d+),(\\d+),(\\d+)$', 'gm');
    var match;
    while ((match = regex.exec(database.candidate_county_csv)) !== null) {
      var candidate_id = match[1];
      var party_id = candidate_id_to_party_id[candidate_id];
      if (!party_id) continue;

      var fips_int = match[2];
      var n_votes = +match[3];

      if (!county_results[party_id]) county_results[party_id] = {};

      var counts = county_results[party_id][fips_int];
      if (!counts) {
        counts = county_results[party_id][fips_int] = {
          candidate_id_to_n_votes: {},
          winner_n_votes: 0
        };
      }

      counts.candidate_id_to_n_votes[candidate_id] = n_votes;

      if (n_votes > counts.winner_n_votes) {
        counts.winner_n_votes = n_votes;
      }
    }
  }
  on_database_change.push(refresh_county_results);

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
   * Returns a className for an svg <path>, from county_results.
   *
   * @param party_id String party ID.
   * @param fips_int String county ID.
   * @param candidate_id String candidate ID.
   * @return One of 'candidate-leads', 'candidate-trails', 'no-results-yet'.
   */
  function lookup_candidate_class(party_id, fips_int, candidate_id) {
    if (!county_results[party_id] || !county_results[party_id][fips_int] || !county_results[party_id][fips_int].winner_n_votes) {
      return 'no-results-yet';
    } else {
      var counts = county_results[party_id][fips_int];
      var n_votes = counts.candidate_id_to_n_votes[candidate_id];
      if (n_votes == counts.winner_n_votes) {
        return 'candidate-leads';
      } else {
        return 'candidate-trails';
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
    var candidate_name = $('tbody tr.highlight-on-map td.candidate', table).text();

    $legend.toggleClass('has-no-results', $('path.no-results-yet', svg).length > 0);
    $legend.toggleClass('has-candidate-leads', !!candidate_name && $('path.candidate-leads', svg).length > 0);
    $legend.toggleClass('has-candidate-trails', !!candidate_name && $('path.candidate-trails', svg).length > 0);
    $legend.find('.candidate-name').text(candidate_name || '');
  }

  function refresh_svg_classes(svg, table, party_id, state_code, no_results_pattern_id) {
    var $candidate_tr = $(table).find('tbody tr.highlight-on-map');
    if ($candidate_tr.length == 0) {
      $candidate_tr = $(table).find('tbody tr:first');
      $candidate_tr.addClass('highlight-on-map');
    }

    var candidate_id = $candidate_tr.attr('data-candidate-id');

    $(svg).find('g.counties path:not(.hover)').each(function() {
      var fips_int = this.getAttribute('data-fips-int');
      var class_name = lookup_candidate_class(party_id, fips_int, candidate_id);
      this.setAttribute('class', class_name);
      if (class_name == 'no-results-yet') {
        this.setAttribute('style', 'fill: url(#' + no_results_pattern_id + ')');
      } else {
        this.setAttribute('style', '');
      }
    });
  }

  /**
   * Adds a <pattern> to the svg, with the given ID.
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
   * `fill: url(#Dem-IA-pattern-no-results)`). Firefox would (correctly) look
   * for `#Dem-IA-pattern-no-results` in the CSS file, which makes no sense.
   */
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

  function monitor_svg(svg, table, party_id, state_code) {
    var pattern_id = party_id + '-' + state_code + '-pattern-no-results';

    add_no_results_yet_pattern_to_svg(svg, pattern_id);

    on_database_change.push(function() {
      if (race_has_results(party_id, state_code)) {
        refresh_svg_classes(svg, table, party_id, state_code, pattern_id);
        refresh_svg_legend(svg, table);
      }
    });

    var $table = $(table);
    $table.on('click', 'tbody tr', function(ev) {
      var $tr = $(ev.currentTarget);

      if (race_has_results(party_id, state_code)) {
        $table.find('tr.highlight-on-map').removeClass('highlight-on-map');
        $tr.addClass('highlight-on-map');
        refresh_svg_classes(svg, table, party_id, state_code, pattern_id);
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
  var interval_ms = 30000;
  var json_url = window.location.toString().split('#')[0] + '.json';

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
          n_votes: $('td.n-votes', this),
          n_delegates: $('td.n-delegates', this)
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
      els[party_id + '-' + state_code] = {
        inner: $('.race-inner', this),
        n_reporting: $('.metadata .n-reporting', this),
        n_total: $('.metadata .n-total', this),
        last_updated: $('.metadata .last-updated time', this.parentNode)
      };
    });
  }

  function update_race_tables_from_database() {
    ensure_els_by_candidate_id_and_state_code_is_populated();

    var trs_in_order = []; // The server gives us the correct ordering.

    database.candidate_state_csv.split('\n').slice(1).forEach(function(line) {
      var arr = line.split(',');
      var candidate_id = arr[0];
      var state_code = arr[1];
      var n_votes = +arr[2];
      var n_delegates = +arr[3];

      var key = candidate_id + '-' + state_code;
      var elems = els_by_candidate_id_and_state_code[key];
      if (elems) {
        trs_in_order.push(elems.tr);
        elems.n_votes.text(format_int(n_votes));
        elems.n_delegates.text(format_int(n_delegates));
      }
    });

    trs_in_order.forEach(function(tr) {
      tr.parentNode.appendChild(tr);
    });
  }

  function update_race_precincts_from_database() {
    ensure_els_by_party_id_and_state_code_is_populated();

    database.race_csv.split('\n').slice(1).forEach(function(line) {
      var arr = line.split(',');
      var party_id = arr[0];
      var state_code = arr[1];
      var n_reporting = +arr[2];
      var n_total = +arr[3];
      var last_updated = new Date(arr[4]);
      if (isNaN(last_updated.getFullYear())) last_updated = null;

      var key = party_id + '-' + state_code;

      var elems = els_by_party_id_and_state_code[key];
      if (elems) {
        elems.inner.removeClass('no-precincts-reporting some-precincts-reporting');
        elems.inner.addClass(n_reporting ? 'some-precincts-reporting' : 'no-precincts-reporting');
        elems.n_reporting.text(format_int(n_reporting));
        elems.n_total.text(format_int(n_total));
        if (last_updated) {
          elems.last_updated.attr('datetime', last_updated.toISOString()).render_datetime();
        }
      }
    });
  }

  function handle_poll_results(json) {
    database = json;
    on_database_change.forEach(function(f) { f(); });
  }

  on_database_change.push(update_race_tables_from_database);
  on_database_change.push(update_race_precincts_from_database);

  $.getJSON(window.location.toString().split('#')[0] + '.json', function(json) {
    handle_poll_results(json);
  })
    .fail(function() { console.warn('Failed to load ' + json_url, this); })
    .always(function() { window.setTimeout(poll_results, interval_ms); });
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

    // Changing n_trs? Change _race.html.haml as well, or page will scroll while loading
    $('table.race').ellipsize_table(5, 'ellipsized', '<button>Show more &#9662;</button>', '<button>Show fewer &#9652;</button>');

    wait_for_font_then('Source Sans Pro', function() {
      fix_text_heights();
      $('.race svg').position_svg_cities();
      add_tooltips();
      poll_results();
      color_counties();
    });
  });
});
