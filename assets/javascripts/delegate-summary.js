function DelegateSummary(el) {
  var current_state_code = null;

  var party_id = el.getAttribute('data-party-id');
  var up_for_grabs_tr = {}; // { int_td, dots_td, pledged_int_td, pledged_dots_td }
  var candidate_trs = {}; // id -> { int_td, dots_td, pledged_int_td, pledged_dots_td }

  function Tr(tr, up_for_grabs) {
    var int_td = tr.querySelector('td.n-delegates-int');
    var dots_td = tr.querySelector('td.n-delegates-dots');
    var pledged_int_td = tr.querySelector('td.n-pledged-delegates-int');
    var pledged_dots_td = tr.querySelector('td.n-pledged-delegates-dots');

    this.rewrite = function rewrite_tr(object) {
      var data;
      if (up_for_grabs) {
        data = {
          n_delegates: object.n_delegates_up_for_grabs || 0,
          n_pledged_delegates: object.n_pledged_delegates_up_for_grabs || 0,
          delegate_dots: object.delegate_dots_up_for_grabs || '',
          pledged_delegate_dots: object.pledged_delegate_dots_up_for_grabs || ''
        };
      } else {
        data = {
          n_delegates: object.n_delegates_in_race_day || 0,
          n_pledged_delegates: object.n_pledged_delegates_in_race_day || 0,
          delegate_dots: object.delegate_dot_groups || '',
          pledged_delegate_dots: object.pledged_delegate_dot_groups || ''
        };
      }

      int_td.textContent = format_int(data.n_delegates);
      dots_td.innerHTML = encoded_dot_groups_html('data-state-code', data.delegate_dots);
      pledged_int_td.textContent = format_int(data.n_pledged_delegates);
      pledged_dots_td.innerHTML = encoded_dot_groups_html('data-state-code', data.pledged_delegate_dots);
    }
  }

  Array.prototype.forEach.call(el.querySelectorAll('tr[data-candidate-id]'), function(tr) {
    var candidate_id = tr.getAttribute('data-candidate-id');
    candidate_trs[candidate_id] = new Tr(tr, false);
  });
  up_for_grabs_tr = new Tr(el.querySelector('tr.up-for-grabs'), true);

  this.set_database = function set_database(database) {
    database.candidates.forEach(function(candidate) {
      var tr = candidate_trs[candidate.id];
      if (tr) {
        tr.rewrite(candidate);
      }
    });
    database.parties.forEach(function(party) {
      if (party.id == party_id) {
        up_for_grabs_tr.rewrite(party);
      }
    });

    database.races.forEach(function(race) {
      if (race.party_id != party_id) return;

      var li = el.querySelector('li[data-state-code=' + race.state_code + ']');
      li.setAttribute('data-n-delegates', '' + race.n_delegates);
      li.setAttribute('data-n-pledged-delegates', '' + race.n_pledged_delegates);
      li.setAttribute('data-n-delegates-with-candidates', '' + race.n_delegates_with_candidates);
      li.setAttribute('data-n-pledged-delegates-with-candidates', '' + race.n_pledged_delegates_with_candidates);
    });

    if (current_state_code) {
      highlight_state(current_state_code);
      // highlight_state() will hide and then show the tooltip, updating counts
    }
  };

  /**
   * Highlight or un-highlight a state.
   */
  function toggle_highlight_state(state_code) {
    if (state_code == current_state_code) {
      unhighlight_state();
      current_state_code = null;
    } else {
      highlight_state(state_code);
      current_state_code = state_code;
    }
  }

  function highlight_state(state_code) {
    unhighlight_state();

    var $highlight_els = $('[data-state-code=' + state_code + ']', el);

    $highlight_els.addClass('highlight');
    $(el).addClass('state-highlighted');

    show_tooltip_for_state_el($highlight_els.last()[0]);
  }

  function unhighlight_state() {
    $('.highlight', el).removeClass('highlight');
    $(el).removeClass('state-highlighted');
    clear_tooltip();
    current_state_code = null;
  }

  var $tooltip = null;

  function show_tooltip_for_state_el(state_el) {
    clear_tooltip();

    var state_name = state_el.getAttribute('data-state-name');
    var race_href = state_el.getAttribute('data-race-href');
    var n_delegates = +state_el.getAttribute('data-n-delegates');
    var n_delegates_with_candidates = +state_el.getAttribute('data-n-delegates-with-candidates');
    var n_pledged_delegates = +state_el.getAttribute('data-n-pledged-delegates');
    var n_pledged_delegates_with_candidates = +state_el.getAttribute('data-n-pledged-delegates-with-candidates');

    var $map = $('.map', state_el);
    var top = $map.position().top + $map.height();

    var html = [
      '<div class="delegate-summary-tooltip" style="top: ' + top + 'px;">',
        '<p class="n-delegates"><strong>' + state_name + '</strong>: ' + format_int(n_delegates_with_candidates) + ' of ' + format_int(n_delegates) + ' delegates accounted for.</p>',
        '<p class="n-pledged-delegates"><strong>' + state_name + '</strong>: ' + format_int(n_pledged_delegates_with_candidates) + ' of ' + format_int(n_pledged_delegates) + ' pledged delegates accounted for.</p>',
        ' <a class="jump-to-race" href="' + race_href + '">Jump to race »</a>',
        '<a class="close" href="#">&times;</a>',
      '</div>'
    ].join('');

    $tooltip = $(html)
      .on('click', function(ev) { ev.stopPropagation(); }) // avoid click.delegate-summary handler
      .on('click', 'a.close', function(ev) { ev.preventDefault(); unhighlight_state() })
      ;

    $(state_el).closest('.state-delegates').append($tooltip);

    // After this event is over, start listening for clicks. Any click
    // closes the delegate summary.
    window.setTimeout(function() {
      $(document).on('click.delegate-summary', unhighlight_state);
    }, 0);
  }

  function clear_tooltip() {
    if (!$tooltip) return;
    $tooltip.remove();
    $tooltip = null;
    $(document).off('click.delegate-summary');
  }

  $(el).on('click', 'li[data-state-code]', function(ev) {
    ev.preventDefault();

    var state_code = ev.currentTarget.getAttribute('data-state-code');

    toggle_highlight_state(state_code);
  });
}
