function countdown($buttons, interval_s, callback_that_calls_a_callback) {
  var start_date = null; // Date we set timeout_id
  var timeout_id = null; // if non-null, we're in "counting" state

  function tick() {
    var now = new Date();

    var remaining_s = Math.ceil(interval_s - (now - start_date) / 1000);

    if (remaining_s <= 0) {
      click();
    } else {
      refresh_text(remaining_s);
      var delay = start_date - now + (interval_s - remaining_s + 1) * 1000;
      if (delay < 10) delay = 10;
      timeout_id = window.setTimeout(tick, delay);
    }
  }

  function start() {
    $buttons.removeClass('clicked').addClass('counting');
    refresh_text(interval_s);

    start_date = new Date();
    timeout_id = window.setTimeout(tick, 1000);
  }

  function click() {
    if (!timeout_id) return; // debounce

    clearTimeout(timeout_id);
    timeout_id = null;

    refresh_text(0);
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

  function refresh_text(remaining_s) {
    var text = '0:' + (remaining_s < 10 ? '0' : '') + remaining_s;
    $buttons.text(text);
  }

  $buttons.on('click.countdown', click);

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
