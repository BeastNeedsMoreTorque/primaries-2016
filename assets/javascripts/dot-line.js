/**
 * A point on a line segment.
 *
 * Each segment has a length, so we can position dots along them. Each segment
 * also has an `on` Boolean: when placing dots originally, we restrict ourselves
 * to `on == true`. That way we don't place dots in between islands, for
 * instance.
 *
 * A DotLine has an initial point, but it isn't a DotLinePoint.
 */
function DotLinePoint(x, y, on, len) {
  if (isNaN(len)) {
    throw 'DotLinePoint len is NaN';
  }

  this.x = x;
  this.y = y;
  this.on = on;
  this.len = len;
}

function DotLine(p1, points, transform_matrix) {
  this.p1 = p1;
  this.points = points;
  this.len = this.points.reduce(function(s, p) { return s + p.len; }, 0);
  this.dot_positions = []; // Numbers along total len
  this.transform_matrix = transform_matrix;
}

/**
 * Sets this.dot_positions, given input of 0..1 dots.
 *
 * Each dot is placed along a DotLinePoint that is "on". The values in
 * `this.dot_positions` are along the _total_ len: on LinePoints that may
 * be `on` or not `on`.
 *
 * Assumes the input is sorted.
 */
DotLine.prototype.place_dots = function(relative_positions) {
  var out = this.dot_positions;

  var len_on = this.points.reduce(function(s, p) { return p.on ? s + p.len : s; }, 0);

  var len_on_so_far = 0;
  var len_so_far = 0;
  var last_point = this.p1;
  var next_point_i = 0;
  var next_point = this.points[0];

  for (var i = 0; i < relative_positions.length; i++) {
    var position = relative_positions[i] * len_on;

    // Advance to the line segment this point will be on.
    //
    // Assume the first line segment is never "on". (It makes the math easier,
    // and we know it's the case.
    while (len_so_far + (next_point.on ? next_point.len : 0) < position) {
      len_so_far += next_point.len;
      if (next_point.on) {
        len_on_so_far += next_point.len;
      }

      last_point = next_point;
      next_point_i += 1;
      next_point = this.points[next_point_i];
    }

    // Now we know we want to place the dot between last_point and point. We
    // merely need to find out how far *along* that path to place it.
    //
    // Assume next_point.len > 0, because the while loop above guarantees it.
    out.push(len_so_far + (position - len_on_so_far));
  }
};

/**
 * Returns an Array of {x, y} dot positions.
 *
 * If `t` is set (a Number from 0..1), subtract `t * len` from the position
 * of every dot along the path. Don't return any dots if the result is negative.
 */
DotLine.prototype.get_dot_coordinates = function(t) {
  var out = [];

  var offset = t * this.len;

  var dots = this.dot_positions;
  var len_so_far = 0;
  var last_point = this.p1;
  var next_point_i = 0;
  var next_point = this.points[next_point_i];

  for (var i = 0; i < dots.length; i++) {
    var position = dots[i] - offset;

    if (position <= 0) {
      continue;
    }

    while (len_so_far + next_point.len < position) {
      len_so_far += next_point.len;
      last_point = next_point;
      next_point_i += 1;
      next_point = this.points[next_point_i];
    }

    // Calculate `t`, a number from 0..1 describing the fraction along the next
    // point that we want to draw at.
    //
    // Assume next_point.len > 0, because the while loop above guarantees it.
    var t = (position - len_so_far) / next_point.len;

    var dx = next_point.x - last_point.x;
    var dy = next_point.y - last_point.y;

    out.push({
      x: last_point.x + t * dx,
      y: last_point.y + t * dy
    });
  }

  return out;
}

/**
 * The number of dots that have a position less than `t * len`.
 *
 * In vernacular: the number of dots that have entered the hole.
 */
DotLine.prototype.get_n_dots_before = function(t) {
  var n = 0;
  var cutoff = t * this.len;

  var dots = this.dot_positions;

  for (var i = 0; i < dots.length; i++) {
    if (dots[i] > cutoff) {
      return i;
    }
  }

  return dots.length;
};

/**
 * Builds a DotLine from an initial {x,y} point and an SVG Path description.
 */
DotLine.parse = function(p1, d, transform_matrix) {
  var subpath_point = null;
  var
    x1 = p1.x, y1 = p1.y, // previous point
    x2, y2,               // next point
    dx, dy,               // x2-x1, y2-y1
    mx, my                // coordinates of last "M" command (for "Z")
    ;

  var points = [];

  var regex = /([MlvhZ ])(?:(-?\d+)(?:,(-?\d+))?)?/g;
  while ((match = regex.exec(d)) != null) {
    switch (match[1]) {
      case 'M':
        mx = x2 = parseInt(match[2], 10);
        my = y2 = parseInt(match[3], 10);
        dx = x2 - x1;
        dy = y2 - y1;
        points.push(new DotLinePoint(x2, y2, false, Math.sqrt(dx * dx + dy * dy)));
        x1 = x2;
        y1 = y2;
        break;
      case 'l':
      case ' ':
        dx = parseInt(match[2], 10);
        dy = parseInt(match[3], 10);
        x2 = x1 + dx;
        y2 = y1 + dy;
        points.push(new DotLinePoint(x2, y2, true, Math.sqrt(dx * dx + dy * dy)));
        x1 = x2;
        y1 = y2;
        break;
      case 'v':
        dy = parseInt(match[2], 10);
        y2 = y1 + dy;
        points.push(new DotLinePoint(x1, y2, true, dy > 0 ? dy : -dy));
        y1 = y2;
        break;
      case 'h':
        dx = parseInt(match[2], 10);
        x2 = x1 + dx;
        points.push(new DotLinePoint(x2, y1, true, dx > 0 ? dy : -dy));
        x1 = x2;
        break;
      case 'Z':
        dx = mx - x1;
        dy = my - y1;
        points.push(new DotLinePoint(mx, my, true, Math.sqrt(dx * dx + dy * dy)));
        x1 = mx;
        y1 = my;
        break;
    }
  }

  return new DotLine(p1, points, transform_matrix);
};
