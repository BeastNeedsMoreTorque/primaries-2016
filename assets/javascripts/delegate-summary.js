function DelegateSummary(el) {
  var $el = $(el);
  var current_state_code = null;

  var party_id = el.getAttribute('data-party-id');
  var up_for_grabs_tr = {}; // { int_td, dots_td, pledged_int_td, pledged_dots_td }
  var candidate_trs = {}; // id -> { int_td, dots_td, pledged_int_td, pledged_dots_td }

  function Tr(tr, up_for_grabs) {
    var $int_td = $('td.n-delegates-int', tr);
    var $dots_td = $('td.n-delegates-dots', tr);
    var $pledged_int_td = $('td.n-pledged-delegates-int', tr);
    var $pledged_dots_td = $('td.n-pledged-delegates-dots', tr);

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

      $int_td.text(format_int(data.n_delegates));
      $dots_td.assign_encoded_dot_groups('data-state-code', data.delegate_dots);
      $pledged_int_td.text(format_int(data.n_pledged_delegates));
      $pledged_dots_td.assign_encoded_dot_groups('data-state-code', data.pledged_delegate_dots);
    }
  }

  $('tr[data-candidate-id]', el).each(function() {
    var candidate_id = this.getAttribute('data-candidate-id');
    candidate_trs[candidate_id] = new Tr(this, false);
  });
  up_for_grabs_tr = new Tr($('tr.up-for-grabs', el).get(0), true);

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

    if (current_state_code) {
      highlight_state(current_state_code);
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
      unhighlight_state();
      highlight_state(state_code);
      current_state_code = state_code;
    }
  }

  function highlight_state(state_code) {
    $('[data-state-code=' + state_code + ']', el).addClass('highlight');
    $el.addClass('state-highlighted');
  }

  function unhighlight_state() {
    $('.highlight', el).removeClass('highlight');
    $el.removeClass('state-highlighted');
    current_state_code = null;
  }

  $el.on('click', 'li[data-state-code]', function(ev) {
    ev.preventDefault();

    var state_code = ev.currentTarget.getAttribute('data-state-code');

    toggle_highlight_state(state_code);
  });
}
