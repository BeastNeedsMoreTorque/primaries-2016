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

  function build_span(font_family) {
    var span = document.createElement('span');
    span.style.position = 'absolute';
    span.style.visibility = 'hidden';
    span.style.fontFamily = font_family;
    span.style.fontSize = '20px';
    span.textContent = '.';
    document.body.appendChild(span);
    return span;
  }

  var span1 = build_span('monospace');
  var width1 = span1.getBoundingClientRect().width;

  var span2 = build_span(font_name);

  function finished_wait_for_font() {
    document.body.removeChild(span1);
    document.body.removeChild(span2);
    // Go on next tick. It helps with profiling that the callback isn't nested
    // in the wait_for_font() call.
    window.setTimeout(callback, 0);
  }

  function is_font_loaded() {
    var width2 = span2.getBoundingClientRect().width;
    return width2 != width1;
  }

  function tick() {
    if (is_font_loaded()) {
      finished_wait_for_font();
    } else {
      window.setTimeout(tick, 50);
    }
  }

  tick();
}

