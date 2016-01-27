//= require './vendor/jquery-2.2.0.js'

/** Waits for the specified font to load, then runs the given code.
  *
  * This is important when calculating dimensions dynamically. Browsers don't
  * tend to flash wrong-font text these days, but they *do* let you calculate
  * width and height of text whose font hasn't been loaded; those measurements
  * are in the fallback font, which is usually wrong.
  *
  * This code should work for any non-monospace font.
  */
function wait_for_font_then(font_name, callback) {
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
    console.log('loaded');
    callback();
  } else {
    console.log('wait');
    window.setTimeout(function() { wait_for_font_then(font_name, callback); }, 50);
  }
}

