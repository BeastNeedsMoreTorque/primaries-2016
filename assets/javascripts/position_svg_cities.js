function position_svg_cities(svgs) {
  // We'll position all <text>s at once, to avoid repaints. That means going
  // through all <svg>s before altering the DOM.
  var tasks = []; // { g: <g>, text: <text>, x: Number, y: Number }

  function trial_rectangles(original_bbox) {
    var margin_x = 6; // px between dot and text
    var margin_y = 4; // px between dot and text

    var x = original_bbox.x;
    var y = original_bbox.y;
    var width = original_bbox.width;
    var height = original_bbox.height;

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

  function rects_intersect(rect1, rect2) {
    return rect1.x < rect2.x + rect2.width
      && rect1.x + rect1.width > rect2.x
      && rect1.y < rect2.y + rect2.height
      && rect1.height + rect1.y > rect2.y;
  }

  function build_tasks_for_svg(svg) {
    var viewBoxStrings = svg.getAttribute('viewBox').split(' ');
    // Assume origin x and y are `0`
    var width = +viewBoxStrings[2];
    var height = +viewBoxStrings[3];

    var ret = [];
    var rects = []; // Array of { x, y, width, height } Objects we've placed

    function rect_fits(rect) {
      if (rect.x < 0) return false;
      if (rect.y < 0) return false;
      if (rect.x + rect.width > width) return false;
      if (rect.y + rect.height > height) return false;

      return rects.every(function(rect2) { return !rects_intersect(rect, rect2); });
    }

    var texts = []; // Array of { text, rect, x, y }
    Array.prototype.forEach.call(svg.querySelectorAll('text'), function(el) {
      texts.push({
        el: el,
        bbox: el.getBBox()
      });
    });
    if (texts.length == 0) return ret;

    var g = texts[0].el.parentNode;

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
    texts.sort(function(o1, o2) { return o1.bbox.y - o2.bbox.y; });

    texts.forEach(function(o) {
      var potential_rects = trial_rectangles(o.bbox);

      for (var i = 0; i < potential_rects.length; i++) {
        var r = potential_rects[i];
        var rect2 = { x: r[1], y: r[2], width: o.bbox.width, height: o.bbox.height };
        if (rect_fits(rect2)) {
          rects.push(rect2);
          ret.push({ g: g, text: o.el, x: rect2.x, y: rect2.y });
          return;
        }
      }

      console.warn('Could not position text', text);
    });

    return ret;
  }

  Array.prototype.forEach.call(svgs, function(svg) {
    build_tasks_for_svg(svg).forEach(function(task) {
      tasks.push(task);
    });
  });

  tasks.forEach(function(task) {
    // Position the <text> according to our calculations
    task.text.setAttribute('x', task.x);
    task.text.setAttribute('y', task.y);

    // Copy the <text> into two: a <text class="background" and a <text class="foreground">
    var text2 = task.text.cloneNode(true);

    task.text.setAttribute('class', 'background');
    text2.setAttribute('class', 'foreground');

    task.g.appendChild(text2);
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
$.fn.position_svg_cities = function() {
  position_svg_cities(this);
};
