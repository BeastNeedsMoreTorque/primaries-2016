$(function() {
  $('a[href="#state-race-days-by-date"]').click(function(ev) {
    ev.preventDefault();
    switch_to('date');
  });
  $('a[href="#state-race-days-by-state"]').click(function(ev) {
    ev.preventDefault();
    switch_to('state');
  });

  $flipper = $('.state-race-days .flipper');
  $toggle = $('.state-race-days-toggle');

  function reset_height() {
    $flipper.children().css({ position: 'absolute' });
    $flipper.height($flipper.children('.selected').height());
  }

  // Shows 'date' and hides 'state', or vice-versa.
  function switch_to(name) {
    history.replaceState({}, '', '#state-race-days-by-' + name);

    $toggle.children('.selected').removeClass('selected');
    $toggle.children('.by-' + name).addClass('selected');

    $flipper.children('.selected').removeClass('selected');
    $flipper.children('#state-race-days-by-' + name).addClass('selected');
    $flipper[0].className = name + '-selected flipper';

    reset_height();
  }

  wait_for_font_then('Source Sans Pro', function() {
    if (window.location.hash == '#state-race-days-by-state') {
      switch_to('state');
    } else {
      reset_height();
    }
  });

  $(window).on('resize', reset_height);
});
