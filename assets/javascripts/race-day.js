(function() {
  var database = null;
  var on_database_change = []; // Array of zero-argument callbacks
  function set_database(new_database, nodes) {
    database = new_database;
    on_database_change.forEach(function(f) { f(database, nodes); });
  }

  var include_unpledged_delegates = true;
  var on_include_unpledged_delegates_changed = [];
  function set_include_unpledged_delegates(value) {
    include_unpledged_delegates = value;
    on_include_unpledged_delegates_changed.forEach(function(callback) { callback(value); });
  }

  function n_precincts_text(n) {
    return n == 1 ? '1 precinct' : (n + ' precincts');
  }

  function n_precincts_reporting_text(reporting, total) {
    if (total == 0) {
      return 'There are no precincts here';
    } else {
      return reporting + ' of ' + n_precincts_text(total) + ' reporting (' + format_percent_int(100 * reporting / total) + '%)';
    }
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
              '<th class="n-votes"></th>' +
              '<th class="percent-vote">%</th>' +
            '</tr>' +
          '</thead>' +
          '<tbody></tbody>' +
        '</table>' +
        '<p class="n-votes-footnote"><span class="asterisk">*</span> <span class="text"></span></p>' +
        '<p class="precincts"></p>' +
      '</div></div>');
    var svg_hover_path = null;

    function update_tooltip(county_name, race, geo_race, candidate_geo_races, highlight_candidate_id, is_from_touch) {
      $tooltip.find('h4').text(county_name);

      if (geo_race) {
        $tooltip.find('table').show();
        $tooltip.find('th.n-votes').text(race.n_votes_tooltip_th || 'Votes');
        $tooltip.find('p.precincts')
          .removeClass('no-precincts-note')
          .text(n_precincts_reporting_text(geo_race.n_precincts_reporting, geo_race.n_precincts_total))
          ;

        if (race.n_votes_footnote) {
          $tooltip.find('th.n-votes').append('<span class="asterisk">*</span>');
          $tooltip.find('p.n-votes-footnote .text').text(race.n_votes_footnote).show();
        } else {
          $tooltip.find('p.n-votes-footnote').hide();
        }
        $tooltip.toggleClass('opened-from-touch', is_from_touch);

        var $tbody = $tooltip.find('tbody').empty();

        candidate_geo_races
          .forEach(function(cgr) {
            var candidate = database.candidates_by_id[cgr.candidate_id];

            $tr = $('<tr><td class="candidate"></td><td class="n-votes"></td><td class="percent-vote"></td></tr>')
              .toggleClass('highlight-on-map', cgr.candidate_id == highlight_candidate_id);

            $tr.find('.candidate').text(candidate.last_name);
            $tr.find('.n-votes').text(format_int(cgr.n_votes));
            $tr.find('.percent-vote').text(geo_race.n_votes ? format_percent(100 * cgr.n_votes / geo_race.n_votes) : 0);
            $tbody.append($tr);
          });
      } else {
        $tooltip.find('table').hide();
        $tooltip.find('p.precincts').text('No polling places').addClass('no-precincts-note');
      }
    }

    function position_tooltip_near_svg_path(svg_path) {
      var MinTop = 50; // px above which we don't show anything. 3rem =~ 50px

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
      if (path_rect.top - tooltip_rect.height - margin >= MinTop) {
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
      var geo_name = svg_path.getAttribute('data-name');
      var n_votes_tooltip_th = $(svg_path).closest('[data-n-votes-tooltip-th]').attr('data-n-votes-tooltip-th');
      var n_votes_footnote = $(svg_path).closest('[data-n-votes-footnote]').attr('data-n-votes-footnote');
      var party_id = $(svg_path).closest('[data-party-id]').attr('data-party-id');
      var state_code = $(svg_path).closest('[data-state-code]').attr('data-state-code');
      var highlight_candidate_id = $(svg_path).closest('.party-state').find('tr.highlight-on-map').attr('data-candidate-id');
      var geo_id = svg_path.getAttribute('data-fips-int') || svg_path.getAttribute('data-geo-id');
      var geo_race = database.geo_races_by_ids[party_id][geo_id];
      var race = database.races_by_ids[party_id][state_code];
      var candidate_geo_races = database.candidate_geo_races_by_geo_ids[party_id][geo_id];

      if (geo_race) {
        update_tooltip(geo_name, race, geo_race, candidate_geo_races, highlight_candidate_id, is_from_touch);
      } else {
        update_tooltip(geo_name);
      }

      position_tooltip_near_svg_path(svg_path);
    }

    function add_hover_path(svg_path) {
      if (svg_hover_path) throw new Error('There is already a hover path');

      var g = svg_path.parentNode;
      var svg = g.parentNode;
      svg_hover_path = svg_path.cloneNode();
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

    $('.race:not(.not-today) .party-state-map svg').each(function() {
      add_tooltip(this);
    });
  }

  function color_counties() {
    function refresh_geo_class_names(database, nodes) {
      function refresh_geo_class_names_inner(geo_race, paths, is_state) {
        var class_name;
        var leader_slug = geo_race.leader_slug;

        if (leader_slug) {
          var verb = geo_race.n_precincts_reporting == geo_race.n_precincts_total ? 'wins' : 'leads';
          class_name = leader_slug + '-' + verb;
        } else {
          class_name = 'no-results';
        }

        var o = paths[geo_race.party_id][geo_race.geo_id];
        if (o) {
          var path = o.path;
          path.setAttribute('class', class_name + (is_state ? ' state' : ''));

          if (/-leads$/.test(class_name)) {
            var pattern_id_start = 'pattern-' + geo_race.party_id + '-' + geo_race.state_code + '-';

            path.setAttribute('style', 'fill: url(#' + pattern_id_start + class_name + ')');
          } else {
            path.setAttribute('style', '');
          }
        }
      }
      database.county_races.forEach(function(geo_race) { refresh_geo_class_names_inner(geo_race, nodes.county_races); });
      database.race_subcounties.forEach(function(geo_race) { refresh_geo_class_names_inner(geo_race, nodes.race_subcounties); });
      database.races
        .filter(function(r) { return r.party_id == 'GOP' && r.state_code == 'ME'; })
        .forEach(function(race) {
          // It just so happens that `nodes.races` races have a `path` for the
          // state-wide <svg> <path>. We use that to color GOP-ME, which has no
          // county-level results.
          var hacky_race = $.extend({ geo_id: race.state_code }, race);
          refresh_geo_class_names_inner(hacky_race, nodes.races, true);
        });
    }
    on_database_change.push(refresh_geo_class_names);

    function refresh_svg_legend(svg) {
      var legend = svg.nextElementSibling;
      var used_path_classes = {};
      var used_slugs = {};

      Array.prototype.forEach.call(svg.querySelectorAll('g.counties path:not(.hover), g.subcounties path:not(.hover)'), function(path) {
        used_path_classes[path.getAttribute('class')] = null;
      });

      Object.keys(used_path_classes).forEach(function(key) {
        if (key == 'no-results') {
          used_slugs[''] = null;
        } else {
          used_slugs[key.substring(0, key.indexOf('-'))] = null;
        }
      });

      Array.prototype.forEach.call(legend.querySelectorAll('li'), function(li) {
        var slug = li.getAttribute('data-candidate') || '';
        li.setAttribute('class', used_slugs.hasOwnProperty(slug) ? 'enabled' : 'disabled');
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

      function buildPattern(id_fragment, color) {
        var pattern = document.createElementNS(ns, 'pattern');
        pattern.setAttributeNS(null, 'id', 'pattern-' + party_id + '-' + state_code + '-' + id_fragment);
        pattern.setAttributeNS(null, 'width', '20');
        pattern.setAttributeNS(null, 'height', '20');
        pattern.setAttributeNS(null, 'patternUnits', 'userSpaceOnUse');

        var rect = document.createElementNS(ns, 'rect');
        rect.setAttributeNS(null, 'width', '20');
        rect.setAttributeNS(null, 'height', '20');
        rect.setAttributeNS(null, 'fill', color);

        var path = document.createElementNS(ns, 'path');
        path.setAttributeNS(null, 'd', 'M-2,2L2,-2M-2,22L22,-2M18,22L22,18');
        path.setAttributeNS(null, 'stroke-width', '3');
        path.setAttributeNS(null, 'stroke', 'white');

        pattern.appendChild(rect);
        pattern.appendChild(path);

        return pattern;
      }

      var defs = document.createElementNS(ns, 'defs');

      Object.keys(CandidateColors[party_id]).forEach(function(candidate_slug) {
        var color = CandidateColors[party_id][candidate_slug];
        defs.appendChild(buildPattern(candidate_slug + '-leads', color));
      });

      svg.insertBefore(defs, svg.firstChild);
    }

    function monitor_svg(svg, party_id, state_code) {
      add_patterns_to_svg(svg);

      on_database_change.push(function() {
        refresh_svg_legend(svg);
      });
    }

    $('.race:not(.not-today) .party-state-map svg').each(function() {
      var $race = $(this).closest('.race');
      var party_id = $race.attr('data-party-id');
      var state_code = $race.attr('data-state-code');

      monitor_svg(this, party_id, state_code);
    });
  }

  function poll_results() {
    function tr_order_matches_document_order(trs_in_order) {
      // Merge sort two Arrays of <tr> elements
      var document_trs = $('.race:not(.not-today) table.candidates tbody tr').get();

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

    function update_race_tables_from_database(database, nodes) {
      var trs_in_order = []; // The server gives us the correct ordering.

      database.candidate_races.forEach(function(candidate_race) {
        var elems = nodes.candidate_races[candidate_race.candidate_id][candidate_race.state_code];
        trs_in_order.push(elems.tr);
        $(elems.tr).toggleClass('winner', candidate_race.winner);
        elems.n_votes.textContent = format_int(candidate_race.n_votes);
        elems.percent_vote.textContent = format_percent(candidate_race.percent_vote);

        elems.n_delegates_dots.innerHTML = simple_dot_groups_html(candidate_race.n_delegates);
        elems.n_delegates_int.textContent = format_int(candidate_race.n_delegates);
        elems.n_pledged_delegates_dots.innerHTML = simple_dot_groups_html(candidate_race.n_pledged_delegates);
        elems.n_pledged_delegates_int.textContent = format_int(candidate_race.n_pledged_delegates);
      });

      if (!tr_order_matches_document_order(trs_in_order)) {
        trs_in_order.forEach(function(tr) {
          tr.parentNode.appendChild(tr);
        });
      }
    }

    function update_races_from_database(database, nodes) {
      database.races.forEach(function(race) {
        var elems = nodes.races[race.party_id][race.state_code];
        $(elems.div)
          .removeClass('past present future')
          .addClass(race.when_race_happens)
          .removeClass('no-precincts-reporting precincts-reporting')
          .addClass(race.n_precincts_reporting > 0 ? 'precincts-reporting' : 'no-precincts-reporting')
          .toggleClass('has-delegate-counts', race.has_delegate_counts)
          .toggleClass('has-pledged-delegate-counts', race.has_pledged_delegate_counts)
          ;

        Array.prototype.forEach.call(elems.n_precincts, function(el) {
          el.textContent = n_precincts_reporting_text(race.n_precincts_reporting, race.n_precincts_total);
        });

        if (!isNaN(race.last_updated.getFullYear())) {
          elems.last_updated.setAttribute('datetime', race.last_updated.toISOString());
          $(elems.last_updated).render_datetime();
        }

        var dels = elems.n_delegates_with_candidates;
        dels.dots.innerHTML = encoded_dot_groups_html('class', race.delegate_dots);
        dels.int_with_candidates.textContent = format_int(race.n_delegates_with_candidates);
        dels.int_total.textContent = format_int(race.n_delegates);

        dels = elems.n_pledged_delegates_with_candidates;
        dels.dots.innerHTML = encoded_dot_groups_html('class', race.pledged_delegate_dots);
        dels.int_with_candidates.textContent = format_int(race.n_pledged_delegates_with_candidates);
        dels.int_total.textContent = format_int(race.n_pledged_delegates);
      });
    }

    var nodes = new RaceDayNodes();
    function handle_poll_results(json) {
      set_database(new RaceDay(json), nodes);
    }

    on_database_change.push(update_race_tables_from_database);
    on_database_change.push(update_races_from_database);

    function do_poll(callback) {
      //var json_url = window.location.toString().split('#')[0] + '.json';
      var json_url = window.location.toString().split('#')[0].split("?")[0] + '.json';

      $.getJSON(json_url, handle_poll_results)
        .fail(function() { console.warn('Failed to load ' + json_url, this); })
        .always(callback);
    }

    $('button.refresh')
      .countdown(30, do_poll)
      .eq(0).trigger('click.countdown'); // poll immediately on page load, to populate map
  }

  /**
   * Ensures that when Democratic and Republican <div class="status">s are
   * aligned, their heights are identical.
   *
   * This makes the rest of the page flow nicely.
   */
  function line_up_race_divs() {
    var refresh_requested = false;

    function refresh_text_heights() {
      refresh_requested = false;

      $('.race-status, .party-state-map').css({ height: 'auto' });

      $('ul.party-state').each(function() {
        var el = this;

        // Queue up all div resizing so we do it all at once. Do not resize
        // while iterating: that'll cause a repaint per race (20ms total on
        // Super Tuesday in Chrome on a fast dev machine).
        var to_resize = [];

        [ '.race-status', '.party-state-map' ].forEach(function(class_name) {
          var $divs = $(class_name, el);
          if ($divs.length == 2) {
            var rect1 = $divs.get(0).getBoundingClientRect();
            var rect2 = $divs.get(1).getBoundingClientRect();
            if (rect1.top == rect2.top) {
              if (rect1.height > rect2.height) {
                to_resize.push({ div: $divs.get(1), height: $divs.eq(0).height() });
              } else if (rect2.height > rect1.height) {
                to_resize.push({ div: $divs.get(0), height: $divs.eq(1).height() });
              }
            }
          }
        });

        to_resize.forEach(function(o) {
          var div = o.div;
          var height = o.height;
          div.style.height = height + 'px';
        });
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

  function update_include_unpledged_delegates_checkboxes(checked) {
    $('input[name=include-unpledged-delegates]').prop('checked', checked)
  }
  on_include_unpledged_delegates_changed.push(update_include_unpledged_delegates_checkboxes);

  function update_body_include_unpledged_delegates(checked) {
    $('body')
      .toggleClass('show-delegates', checked)
      .toggleClass('show-pledged-delegates', !checked);
  }
  on_include_unpledged_delegates_changed.push(update_body_include_unpledged_delegates);

  function init_delegate_summary() {
    $('.party-delegate-summary').each(function() {
      var summary = new DelegateSummary(this);
      on_database_change.push(summary.set_database);
    });
  }

  function init_include_unpledged_delegates() {
    $(document).on('click', 'input[name=include-unpledged-delegates]', function() {
      set_include_unpledged_delegates(this.checked);
    });
  }

  function init_scroll_spy() {
    var scrollFinder = document.getElementById('scrollfinder');
    if (!scrollFinder) return;

    var $dropdownContainer = $('.dropdown-container', scrollFinder);
    function topCheck() {
      $dropdownContainer.toggleClass('fixed', window.scrollY > scrollFinder.offsetTop);
    }

    var anchors = document.querySelectorAll('a[name]');
    var anchor_map = null; // Array of { top, name } pairs
    function refresh_anchor_map() {
      anchor_map = [];
      // We often have two anchors at the same position. We care about the
      // first in that case; we should ignore the second.
      var last_top = -1;

      Array.prototype.forEach.call(anchors, function(el) {
        var top = el.offsetTop;
        if (top != last_top) {
          // When we resize, we get off by a few pixels, it seems, on Chrome
          // 48. I haven't bothered to investigate; I'll just gives a few
          // pixels' buffer so nobody will notice.
          anchor_map.push({ top: top - 10, name: el.getAttribute('name') });
          last_top = top;
        }
      });
    }

    // Returns the first anchor above/at the current window.scrollY. If
    // there are none, we're at the top of the page; returns `null`.
    function find_current_anchor_name() {
      var top = window.scrollY;
      var ret = null;

      for (var i = 0; i < anchor_map.length; i++) {
        var o = anchor_map[i];
        if (top <= o.top) {
          return ret;
        } else {
          ret = o.name;
        }
      }

      return ret;
    }

    var $dropdown_toggle_label = $dropdownContainer.find('.dropdown-toggle span.label');
    var dropdown_toggle_original_html = $dropdown_toggle_label.html();
    function adjust_dropdown_toggle_label() {
      var anchor_name = find_current_anchor_name();
      var anchor_html;

      if (anchor_name) {
        anchor_html = $dropdownContainer.find('a[href="#' + anchor_name + '"]').html();
      } else {
        anchor_html = dropdown_toggle_original_html;
      }

      $dropdown_toggle_label.html(anchor_html);
    }

    $dropdown_toggle_label.parent().dropdown();

    function refresh_dropdown() {
      topCheck();
      refresh_anchor_map();
      adjust_dropdown_toggle_label();
    }

    window.addEventListener('scroll', topCheck);
    window.addEventListener('scroll', adjust_dropdown_toggle_label);
    window.addEventListener('resize', function() {
      // Since we adjust the height of things in a requestAnimationFrame(),
      // we need to use the results in a requestAnimationFrame(), too.
      window.requestAnimationFrame(refresh_dropdown);
    });

    refresh_dropdown();
  }

  function init_race_day() {
    $('time').render_datetime();

    wait_for_font_then('Source Sans Pro', function() {
      line_up_race_divs();
      init_scroll_spy();
      $('.party-state-map svg').position_svg_cities();
    });

    init_delegate_summary();
    init_include_unpledged_delegates();

    add_tooltips();
    color_counties(); // set up on_database_change
    poll_results(); // send AJAX request
  }

  $(function() {
    init_race_day();
  });
})();
