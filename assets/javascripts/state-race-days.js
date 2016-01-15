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
    var h = 0;
    $flipper.children().css({ position: 'absolute' });
    $flipper.children().each(function() {
      var ch = $(this).height();
      if (ch > h) h = ch;
    });
    $flipper.height(h);
  }

  // Shows 'date' and hides 'state', or vice-versa.
  function switch_to(name) {
    window.location.hash = '#state-race-days-by-' + name;

    $toggle.children('.selected').removeClass('selected');
    $toggle.children('.by-' + name).addClass('selected');

    $flipper.children('.selected').removeClass('selected');
    $flipper.children('.state-race-days-by-' + name).addClass('selected');
    $flipper[0].className = name + '-selected flipper';

    reset_height();
  }

  var $wait_for_fonts_span = $('<span class="waiting-for-fonts-to-load" style="display:none; font-family: foo,Arial;"></span>')
    .appendTo('body');
  function waitForFontThen(font_name, callback) {
    // Render "." in a monospace font and in the desired font. Presumably, the
    // desired font's <span> will be thinner than a monospace one.
    var $span1 = $('<span class="wait-for-font-mono" style="position: absolute; visibility: hidden; font-family: monospace; font-size: 20px;">.</span>')
      .appendTo('body');
    var $span2 = $('<span class="wait-for-font-non-mono" style="position: absolute; visibility: hidden; font-family: ' + font_name + ', monospace; font-size: 20px;">.</span>')
      .appendTo('body');

    var loaded = $span1.width() != $span2.width();
    $span1.remove();
    $span2.remove();

    if (loaded) {
      callback();
    } else {
      window.setTimeout(function() { waitForFontThen(font_name, callback); }, 50);
    }
  }

  waitForFontThen('Source Sans Pro', function() {
    if (window.location.hash == '#state-race-days-by-state') {
      switch_to('state');
    } else {
      reset_height();
    }
  });
});
