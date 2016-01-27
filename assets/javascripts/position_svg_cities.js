function position_svg_cities() {
  var $svg = $(this);
  var $texts = $svg.find('text');

  if ($texts.length == 0) return;

  var viewBoxStrings = $svg[0].getAttribute('viewBox').split(' ');
  // Assume origin x and y are `0`
  var width = +viewBoxStrings[2];
  var height = +viewBoxStrings[3];

  var rects = []; // Array of { x, y, width, height } Objects we've placed

  function rects_intersect(rect1, rect2) {
    return rect1.x < rect2.x + rect2.width
      && rect1.x + rect1.width > rect2.x
      && rect1.y < rect2.y + rect2.height
      && rect1.height + rect1.y > rect2.y;
  }

  function rect_fits(rect) {
    if (rect.x < 0) return false;
    if (rect.y < 0) return false;
    if (rect.x + rect.width > width) return false;
    if (rect.y + rect.height > height) return false;

    return rects.every(function(rect2) { return !rects_intersect(rect, rect2); });
  }

  function trial_rectangles(x, y, width, height) {
    var margin_x = 6; // px between dot and text
    var margin_y = 4; // px between dot and text

    var x_height = Math.round(height / 4); // roughly?
    var y_above = Math.round(y - height - margin_y);
    var y_below = Math.round(y + margin_y - height / 5); // bump it up a bit
    var y_mid = Math.round(y - height / 2 - height / 10); // bump it up a bit
    var x_left = Math.round(x - width - margin_x);
    var x_right = Math.round(x + margin_x);
    var x_mid = Math.round(x - width / 2);

    return [
      [ 'above', x_mid, y_above ],
      [ 'left', x_left, y_mid ],
      [ 'right', x_right, y_mid ],
      [ 'below', x_mid, y_below ],
      [ 'above-right', x_right, y_above ],
      [ 'above-left', x_left, y_above ],
      [ 'below-right', x_right, y_below ],
      [ 'below-left', x_left, y_below ]
    ];
  }

  $texts.get()
    // Sort from north to south. Otherwise, in a situation like this:
    //
    // +---------------+
    // |               |
    // |          2    |
    // |             1 |
    // |               |
    // |               |
    // |               |
    // +---------------+
    //
    // ... city #1's label would go above-left, and city #2's label would
    // overlap no matter what.
    //
    // (See Kansas: Topeka and Overland Park.)
    .sort(function(text1, text2) { return +text1.getAttribute('y') - text2.getAttribute('y'); })
    .forEach(function(text) {
      var x = +text.getAttribute('x');
      var y = +text.getAttribute('y');
      var rect = text.getBBox();
      var potential_rects = trial_rectangles(x, y, rect.width, rect.height);

      for (var i = 0; i < potential_rects.length; i++) {
        var r = potential_rects[i];
        var rect2 = { x: r[1], y: r[2], width: rect.width, height: rect.height };
        if (rect_fits(rect2)) {
          rects.push(rect2);
          text.setAttribute('x', rect2.x);
          text.setAttribute('y', rect2.y);
          text.setAttribute('class', r[0]);
          return;
        }
      }

      console.warn('Could not position text', text);
    });

  // Turn each <text> into a <text class="background"> and <text class="foreground">.
  var cities = $texts[0].parentNode;
  $texts.each(function() {
    var class_name = this.getAttribute('class');
    var text2 = this.cloneNode(true);
    this.setAttribute('class', class_name + ' background');
    text2.setAttribute('class', class_name + ' foreground');
    cities.appendChild(text2);
  });
}

/**
 * Tweaks <text> attributes on all <svg>s, so city labels go where they should.
 *
 * In detail:
 *
 * * Positions labels above, below, to the sides, or to the corners of their
 *   original positions -- whichever fits on the <svg>.
 * * Ensures two labels don't overlap.
 * * Clones each <text> element: the original becomes `class="background"` and
 *   the second becomes `class="foreground"`.
 *
 * Requirements:
 *
 * * Must be called on one or more <svg> elements
 * * The <svg> element must have a `viewBox` attribute
 */
$.fn.position_svg_cities = function() { this.each(position_svg_cities); };
