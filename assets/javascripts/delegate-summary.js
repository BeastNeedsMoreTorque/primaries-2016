function let_user_pick_states(el) {
  var $el = $(el);
  var current_state_code = null;

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

$(function() {
  $('body.race-day .party-delegate-summary').each(function() {
    let_user_pick_states(this);
  });
});
