//= require ./render_time.js
//= require ./format_int.js
//= require ./ellipsize_table.js

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

function position_cities_correctly() {
  function position_svg_cities_correctly(el) {
    var $el = $(el);
    var $texts = $el.find('text');
    var $svg = $texts.closest('svg');
    var viewBoxStrings = $svg[0].getAttribute('viewBox').split(' ');
    var width = +viewBoxStrings[2];
    var height = +viewBoxStrings[3];

    var rects = []; // Array of { x, y, width, height } Objects

    function rects_intersect(rect1, rect2) {
      return rect1.x < rect2.x + rect2.width && rect1.x + rect1.width > rect2.x && rect1.y < rect2.y + rect2.height && rect1.height + rect1.y > rect2.y;
    }

    function rect_fits(rect) {
      if (rect.x < 0) return false;
      if (rect.y < 0) return false;
      if (rect.x + rect.width > width) return false;
      if (rect.y + rect.height > height) return false;

      return rects.every(function(rect2) { return !rects_intersect(rect, rect2); });
    }

    function trial_rectangles(x, y, width, height) {
      var margin = 5; // px between dot and text
      var x_height = height / 4; // roughly?
      return [
        { position: 'above', x: (x - width / 2), y: y - margin, width: width, height: height },
        { position: 'right', x: x + margin, y: y + x_height, width: width, height: height },
        { position: 'left', x: x - width - margin, y: y + x_height, width: width, height: height },
        { position: 'below', x: (x - width / 2), y: (y + height + margin), width: width, height: height }
      ];
    }

    $texts.each(function() {
      var text = this;
      var x = +text.getAttribute('x');
      var y = +text.getAttribute('y');
      var rect = text.getBBox();
      var potential_rects = trial_rectangles(x, y, rect.width, rect.height);

      for (var i = 0; i < potential_rects.length; i++) {
        var r = potential_rects[i];
        if (rect_fits(r)) {
          rects.push(r);
          text.setAttribute('x', r.x);
          text.setAttribute('y', r.y);
          text.setAttribute('class', r.position);
          return;
        }
      }

      console.warn('Could not position text', text);
    });

    // Turn each <text> into a <text class="background"> and <text class="foreground">.
    var cities = $texts[0].parentNode;
    $texts.each(function() {
      var class_name = this.getAttribute('class');
      var text2 = this.cloneNode(true);
      this.setAttribute('class', class_name + ' background');
      text2.setAttribute('class', class_name + ' foreground');
      cities.appendChild(text2);
    });
  }

  $('.party-state-map').each(function() {
    position_svg_cities_correctly(this);
  });
}

function add_tooltips() {
  // One $tooltip for all <svg>s
  var $tooltip = $('<div class="race-tooltip">' +
    '<div class="tooltip-contents">' +
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

  function update_tooltip(county_name, candidates, n_reporting, n_total, last_updated) {
    $tooltip.find('h4').text(county_name);
    $tooltip.find('span.n-reporting').text(format_int(n_reporting));
    $tooltip.find('span.n-total').text(format_int(n_total));
    $tooltip.find('.last-updated time').attr('datetime', last_updated.toISOString()).render_datetime();

    var $tbody = $tooltip.find('tbody').empty();

    candidates.forEach(function(candidate) {
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

  function show_tooltip_for_svg_path(svg_path) {
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

      update_tooltip(county_name, candidates, n_reporting, n_total, last_updated);
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
    svg_hover_path.parentNode.removeChild(svg_hover_path);
    svg_hover_path = null;
  }

  function on_mouseenter() {
    var svg_path = this;
    add_hover_path(svg_path);
    show_tooltip_for_svg_path(svg_path);
  }

  function on_mouseleave() {
    remove_hover_path();
    remove_tooltip();
  }


  function add_tooltip(svg) {
    $(svg)
      .on('mouseenter', 'g.counties path', on_mouseenter)
      .on('mouseleave', 'g.counties path', on_mouseleave);
  }

  $('.party-state-map svg').each(function() {
    add_tooltip(this);
  });
}

function color_counties() {
  var county_results = null; // party_id -> fips_int -> { candidate_id_to_n_votes, winner_n_votes, runner_up_n_votes }

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
          winner_n_votes: 0,
          runner_up_n_votes: 0
        };
      }

      counts.candidate_id_to_n_votes[candidate_id] = n_votes;

      if (n_votes > counts.winner_n_votes) {
        counts.runner_up_n_votes = counts.winner_n_votes;
        counts.winner_n_votes = n_votes;
      } else if (n_votes > counts.runner_up_n_votes) {
        counts.runner_up_n_votes = n_votes;
      }
    }
  }
  on_database_change.push(refresh_county_results);

  /**
   * Returns a className for an svg <path>, from county_results.
   *
   * @param party_id String party ID.
   * @param fips_int String county ID.
   * @param candidate_id String candidate ID.
   * @return One of 'candidate-came-first', 'candidate-came-second',
   *         'candidate-did-badly', 'no-results-yet'. Or the empty String, which
   *         means lookup failed.
   */
  function lookup_candidate_class(party_id, fips_int, candidate_id) {
    var counts = county_results[party_id][fips_int];

    if (!counts) {
      return '';
    } else {
      var n_votes = counts.candidate_id_to_n_votes[candidate_id];
      if (typeof n_votes === 'undefined') {
        return '';
      } else {
        if (counts.winner_n_votes == 0) {
          return 'no-results-yet';
        } else if (n_votes == counts.winner_n_votes) {
          return 'candidate-came-first';
        } else if (n_votes == counts.runner_up_n_votes) {
          return 'candidate-came-second';
        } else {
          return 'candidate-did-badly';
        }
      }
    }
  }

  function refresh_svg_classes(svg, table, party_id) {
    $(table).find('.highlight-on-map').removeClass('highlight-on-map');
    var $candidate_tr = $(table).find('tbody tr:first');
    $candidate_tr.addClass('highlight-on-map');

    var candidate_id = $candidate_tr.attr('data-candidate-id');

    $(svg).find('g.counties path:not(.hover)').each(function() {
      var fips_int = this.getAttribute('data-fips-int');
      var class_name = lookup_candidate_class(party_id, fips_int, candidate_id);
      this.setAttribute('class', class_name);
    });
  }

  function monitor_svg(svg, table, party_id) {
    on_database_change.push(function() {
      refresh_svg_classes(svg, table, party_id);
    });
  }

  $('.party-state-map svg').each(function() {
    var $race = $(this).closest('.race');
    var $table = $race.find('table');
    var party_id = $race.attr('data-party-id');

    monitor_svg(this, $table[0], party_id);
  });
}

function poll_results() {
  var interval_ms = 30000;
  var json_url = window.location.toString().split('#')[0] + '.json';

  var els_by_candidate_id_and_state_code = null; // Maps "123-CA" to { n_votes, n_delegates }.
  function ensure_els_by_candidate_id_and_state_code_is_populated() {
    if (els_by_candidate_id_and_state_code) return;

    var els = els_by_candidate_id_and_state_code = {};

    $('.race[data-state-code]').each(function() {
      var state_code = this.getAttribute('data-state-code');

      $('tr[data-candidate-id]', this).each(function() {
        var candidate_id = this.getAttribute('data-candidate-id');

        els[candidate_id + '-' + state_code] = {
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

    database.candidate_state_csv.split('\n').slice(1).forEach(function(line) {
      var arr = line.split(',');
      var candidate_id = arr[0];
      var state_code = arr[1];
      var n_votes = +arr[2];
      var n_delegates = +arr[3];

      var key = candidate_id + '-' + state_code;
      var elems = els_by_candidate_id_and_state_code[key];
      if (elems) {
        elems.n_votes.text(format_int(n_votes));
        elems.n_delegates.text(format_int(n_delegates));
      }
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

      var key = party_id + '-' + state_code;

      var elems = els_by_party_id_and_state_code[key];
      if (elems) {
        elems.inner.removeClass('no-precincts-reporting some-precincts-reporting');
        elems.inner.addClass(n_reporting ? 'some-precincts-reporting' : 'no-precincts-reporting');
        elems.n_reporting.text(format_int(n_reporting));
        elems.n_total.text(format_int(n_total));
        elems.last_updated.attr('datetime', last_updated.toISOString()).render_datetime();
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

$(function() {
  $('body.race-day').each(function() {
    $('time').render_datetime();

    // Changing n_trs? Change _race.html.haml as well, or page will scroll while loading
    $('table.race').ellipsize_table(5, 'ellipsized', '<button>Show more…</button>', '<button>Show fewer…</button>');

    wait_for_font_then('Source Sans Pro', function() {
      position_cities_correctly();
      add_tooltips();
      poll_results();
      color_counties();
    });
  });
});
