function countdown($buttons, interval_s, callback_that_calls_a_callback) {
  var remaining_s = null;
  var timer_id = null; // if non-null, we're in "counting" state

  function tick() {
    --remaining_s;

    if (remaining_s <= 0) {
      click();
    } else {
      refresh_text();
    }
  }

  function start() {
    $buttons.removeClass('clicked').addClass('counting');
    remaining_s = interval_s;
    refresh_text();

    timer_id = window.setInterval(tick, 1000);
  }

  function click() {
    if (!timer_id) return; // debounce

    clearInterval(timer_id);
    timer_id = null;

    remaining_s = 0;
    refresh_text();
    $buttons.removeClass('counting').addClass('clicked');

    var startDate = new Date();
    function start_or_wait_for_spin() {
      var endDate = new Date();
      if (endDate - startDate < 1000) {
        window.setTimeout(start, 1000 - (endDate - startDate));
      } else {
        start();
      }
    }

    callback_that_calls_a_callback(start_or_wait_for_spin);
  }

  function refresh_text() {
    var text = '0:' + (remaining_s < 10 ? '0' : '') + remaining_s;
    $buttons.text(text);
  }

  $buttons.on('click', click);

  start();
}

/**
 * Turns a <button> into a countdown timer.
 *
 * The button has two states, as CSS classes: "counting" and "clicked". State
 * diagram:
 *
 *                   --(user clicks button)--->    
 *   [counting]      --(countdown reaches 0)-->       [clicked]
 *               <--(callback calls its argument)--
 *
 * The button text will be set every second.
 *
 * You can pass multiple buttons at once. They'll all be synchronized: click one
 * and all will be clicked. (Clicking calls the callback.)
 */
$.fn.countdown = function(interval_s, callback_that_calls_a_callback) {
  countdown(this, interval_s, callback_that_calls_a_callback);
  return this;
}
