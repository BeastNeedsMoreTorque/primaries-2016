/**
 * Animating one race day means:
 *
 * 1. Showing all the states
 * 2. Turning the states into dots
 * 3. Moving dots to candidate holes and moving horses
 */
function StepAnimation(horse_race, step_number) {
  this.horse_race = horse_race;
  this.step_number = step_number;
  this.cancel = false;

  var race_day = this.race_day = horse_race.data.race_days[step_number];
  var candidates = this.candidates = {};

  for (var candidate_id in horse_race.candidates_up_to_now) {
    var c = horse_race.candidates_up_to_now[candidate_id];
    var n_delegates = race_day.races.reduce(function(s, r) { return s + (r.candidate_n_delegates[candidate_id] || 0); }, 0);

    candidates[candidate_id] = {
      els: c.els,
      start_n_delegates: c.n_delegates,
      end_n_delegates: c.n_delegates + n_delegates
    };
  }
}

StepAnimation.prototype.start = function() {
  this.show_states();
};

/**
 * Calls step(t) repeatedly, then next_step().
 *
 * t is always between 0 to 1. It represents time, for animation functions.
 */
StepAnimation.prototype.animate_step = function(duration, step, next_step) {
  if (this.cancel) { return next_step(); }

  var t1 = new Date();
  var _this = this;

  function do_step() {
    if (_this.cancel) { return next_step(); }

    var t = new Date() - t1;
    var fraction = Math.min(1, t / duration);

    step(fraction);

    if (fraction == 1) {
      next_step();
    } else {
      window.requestAnimationFrame(do_step);
    }
  }

  window.requestAnimationFrame(do_step);
};

function draw_path(ctx, path) {
  var x, y, dx, dy, match;

  ctx.beginPath();

  var regex = /([MlvhZ ])(?:(-?\d+)(?:,(-?\d+))?)?/g;
  while ((match = regex.exec(path)) != null) {
    switch (match[1]) {
      case 'M':
        x = parseInt(match[2], 10);
        y = parseInt(match[3], 10);
        ctx.moveTo(x, y);
        break;
      case 'l':
      case ' ':
        dx = parseInt(match[2], 10);
        dy = parseInt(match[3], 10);
        x += dx;
        y += dy;
        ctx.lineTo(x, y);
        break;
      case 'v':
        dy = parseInt(match[2], 10);
        y += dy;
        ctx.lineTo(x, y);
        break;
      case 'h':
        dx = parseInt(match[2], 10);
        x += dx;
        ctx.lineTo(x, y);
        break;
      case 'Z':
        ctx.closePath();
        // This changes x and y, but we don't care: if there's another
        // instruction, it's an 'M'.
        break;
    }
  }

  ctx.stroke();
}

function build_canvas(parent_div) {
  var w = parent_div.clientWidth;
  var h = 300;

  var canvas = document.createElement('canvas');
  canvas.width = w;
  canvas.height = h;

  parent_div.appendChild(canvas);

  return canvas;
}

/**
 * A candidate and its group of dots.
 *
 * Each dot will animate from its start position to its end one.
 */
function AnimatedDotSet(candidate_id, target_xy, dots) {
  this.candidate_id = candidate_id;
  this.target_xy = target_xy;
  this.dots = dots;

  this._scratch = this.dots.map(function(xy) {
    var dx = xy.x - target_xy.x;
    var dy = xy.y - target_xy.y;
    var d = Math.sqrt(dx * dx + dy * dy);

    return {
      x: xy.x,
      y: xy.y,
      dx: dx,
      dy: dy,
      d: d
    };
  });

  this._max_d = Math.max.apply(null, this._scratch.map(function(x) { return x.d; }));
}

/**
 * Returns {x, y} Objects for time t, where t is between 0 and 1.
 *
 * At t=1, all dot positions are 
 */
AnimatedDotSet.prototype.get_dots_at = function(t) {
  // Move the farthest dot linearly; move the rest at the same speed.
  var d_so_far = t * this._max_d;

  var ret = [];

  for (var i = 0; i < this._scratch.length; i++) {
    var scratch = this._scratch[i];

    if (scratch.d > d_so_far) {
      var m = d_so_far / scratch.d;
      ret.push({ x: scratch.x - scratch.dx * m, y: scratch.y - scratch.dy * m });
    }
  }

  return ret;
};

/**
 * Returns number of dots that have disappeared by time t.
 */
AnimatedDotSet.prototype.get_n_dots_completed_at = function(t) {
  var d_so_far = t * this._max_d;
  return this._scratch.reduce(function(s, x) { return s + (x.d > d_so_far ? 0 : 1); }, 0);
};

/**
 * A point on a line segment.
 *
 * Each segment has a length, so we can position dots along them. Each segment
 * also has an `on` Boolean: when placing dots originally, we restrict ourselves
 * to `on == true`. That way we don't place dots in between islands, for
 * instance.
 *
 * A Line has an initial point, but it isn't a LinePoint.
 */
function LinePoint(x, y, on, len) {
  if (isNaN(len)) {
    throw 'LinePoint len is NaN';
  }

  this.x = x;
  this.y = y;
  this.on = on;
  this.len = len;
}

function Line(p1, points, transform_matrix) {
  this.p1 = p1;
  this.points = points;
  this.len = this.points.reduce(function(s, p) { return s + p.len; }, 0);
  this.dot_positions = []; // Numbers along total len
  this.transform_matrix = transform_matrix;
}

/**
 * Sets this.dot_positions, given input of 0..1 dots.
 *
 * Each dot is placed along a LinePoint that is "on". The values in
 * `this.dot_positions` are along the _total_ len: on LinePoints that may
 * be `on` or not `on`.
 *
 * Assumes the input is sorted.
 */
Line.prototype.place_dots = function(relative_positions) {
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
Line.prototype.get_dot_coordinates = function(t) {
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
Line.prototype.get_n_dots_before = function(t) {
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
 * Builds a Line from an initial {x,y} point and an SVG Path description.
 */
Line.parse = function(p1, d, transform_matrix) {
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
        points.push(new LinePoint(x2, y2, false, Math.sqrt(dx * dx + dy * dy)));
        x1 = x2;
        y1 = y2;
        break;
      case 'l':
      case ' ':
        dx = parseInt(match[2], 10);
        dy = parseInt(match[3], 10);
        x2 = x1 + dx;
        y2 = y1 + dy;
        points.push(new LinePoint(x2, y2, true, Math.sqrt(dx * dx + dy * dy)));
        x1 = x2;
        y1 = y2;
        break;
      case 'v':
        dy = parseInt(match[2], 10);
        y2 = y1 + dy;
        points.push(new LinePoint(x1, y2, true, dy > 0 ? dy : -dy));
        y1 = y2;
        break;
      case 'h':
        dx = parseInt(match[2], 10);
        x2 = x1 + dx;
        points.push(new LinePoint(x2, y1, true, dx > 0 ? dy : -dy));
        x1 = x2;
        break;
      case 'Z':
        dx = mx - x1;
        dy = my - y1;
        points.push(new LinePoint(mx, my, true, Math.sqrt(dx * dx + dy * dy)));
        x1 = mx;
        y1 = my;
        break;
    }
  }

  return new Line(p1, points, transform_matrix);
};

/**
 * Builds a transform for race i of n.
 *
 * Assumes:
 *
 * * output is 300x300, input is 1000,1000.
 * * races should be evenly spaced in `w` pixels total, and this one is race number `i` of `n`
 */
function build_race_transform_matrix(i, n, w) {
  return [
    300 / 1000,
    0,
    0,
    300 / 1000,
    (i + 0.5) * w / n - 300 / 2,
    0
  ];
}

function matrix_multiply(matrix, coords) {
  var x = coords[0];
  var y = coords[1];

  return [
    x * matrix[0] + y * matrix[2] + matrix[4],
    x * matrix[1] + y * matrix[3] + matrix[5]
  ];
}

StepAnimation.prototype.show_states = function() {
  var _this = this;

  var canvas;

  function step(t) {
    if (!canvas) {
      var div = _this.horse_race.els.div;
      canvas = _this.state_canvas = build_canvas(div);

      var ctx = canvas.getContext('2d');

      var races = _this.race_day.races;
      var paths = _this.horse_race.state_paths;

      for (var i = 0; i < races.length; i++) {
        var race = races[i];

        ctx.save();

        var transform = build_race_transform_matrix(i, races.length, canvas.width);
        ctx.setTransform.apply(ctx, transform);

        draw_path(ctx, paths[race.state_code]);
        ctx.strokeStyle = 'blue';
        ctx.lineWidth = 10;
        ctx.stroke();

        ctx.restore();
      }
    }

    canvas.style.opacity = t;
  }

  this.animate_step(1000, step, function() { _this.show_dots(); });
};

StepAnimation.prototype.show_dots = function() {
  var _this = this;

  function candidate_state_line(candidate_id, state_code, transform_matrix) {
    var line = Line.parse({ x: 0, y: 0 }, _this.horse_race.state_paths[state_code], transform_matrix);
    line.candidate_id = candidate_id;
    return line;
  }

  // Builds [ { candidate_id: 'id', dots: Array[{x,y}] } ] for a race.
  function candidate_race_dots(race, transform_matrix) {
    var ret = [];
    var candidates = [];

    for (var id in race.candidate_n_delegates) {
      var n = race.candidate_n_delegates[id];
      if (n == 0) continue;

      var line = candidate_state_line(id, race.state_code, transform_matrix);
      if (!line) continue;

      candidates.push({ id: id, n_dots_remaining: n, line: line, dot_positions: [] });
    }

    var n = candidates.reduce(function(s, c) { return s + c.n_dots_remaining; }, 0);
    var step = 1 / n;
    var t = step /2;

    // Interweave candidate dots: give the dots round-robin to the candidates
    var remaining = candidates.slice(0);
    while (remaining.length > 0) {
      var candidate = remaining.shift();
      candidate.dot_positions.push(t);
      t += step;
      candidate.n_dots_remaining -= 1;

      if (candidate.n_dots_remaining > 0) {
        remaining.push(candidate);
      }
    }

    return candidates.map(function(c) {
      c.line.place_dots(c.dot_positions);
      return {
        candidate_id: c.id,
        dots: c.line.get_dot_coordinates(0)
      };
    });
  }

  var canvas;         // <canvas>
  var width;          // width of <canvas>
  var ctx;            // 2d context
  var candidate_dots; // Array[AnimatedDotSet]

  function initialize() {
    var div = _this.horse_race.els.div;
    canvas = _this.dot_canvas = build_canvas(div);
    width = canvas.width;
    ctx = canvas.getContext('2d');

    var races = _this.race_day.races;
    var partial_dot_sets = {}; // candidate_id -> Array of dots
    for (var i = 0; i < races.length; i++) {
      var transform = build_race_transform_matrix(i, races.length, canvas.width);
      var race_dots = candidate_race_dots(races[i], transform);

      for (var j = 0; j < race_dots.length; j++) {
        var dots = race_dots[j];
        if (!partial_dot_sets.hasOwnProperty(dots.candidate_id)) {
          partial_dot_sets[dots.candidate_id] = [];
        }

        var transformed_dots = dots.dots.map(function(xy) {
          return {
            x: xy.x * transform[0] + xy.y * transform[2] + transform[4],
            y: xy.x * transform[1] + xy.y * transform[3] + transform[5]
          };
        });

        partial_dot_sets[dots.candidate_id] = partial_dot_sets[dots.candidate_id].concat(transformed_dots);
      }
    }

    candidate_dots = [];
    for (var candidate_id in partial_dot_sets) {
      var els = _this.horse_race.candidate_els[candidate_id];
      if (!els) continue;

      var target_el = els.target;
      var target_xy = { x: target_el.offsetLeft, y: 250 };
      candidate_dots.push(new AnimatedDotSet(candidate_id, target_xy, partial_dot_sets[candidate_id]));
    }

    _this.state_canvas.parentNode.removeChild(_this.state_canvas);
    _this.state_canvas = null;
  }

  function step(t) {
    if (!ctx) initialize();

    ctx.fillStyle = 'blue';
    ctx.beginPath();

    var radius = 3; // px

    for (var i = 0; i < candidate_dots.length; i++) {
      var dot_set = candidate_dots[i];
      var dots = dot_set.get_dots_at(t);

      for (var j = 0; j < dots.length; j++) {
        var dot = dots[j];
        ctx.moveTo(dot.x, dot.y);
        ctx.arc(dot.x, dot.y, radius, 0, Math.PI * 2);
        ctx.closePath();
      }

      var n_complete = dot_set.get_n_dots_completed_at(t);
      var candidate = _this.candidates[dot_set.candidate_id];
      var n_delegates = candidate.start_n_delegates + n_complete;
      var percent = 100 * n_delegates / _this.horse_race.data.n_delegates_needed;
      candidate.els.n_delegates.textContent = format_int(n_delegates);
      candidate.els.marker.style.left = percent + '%';
    }

    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.fill();
  }

  this.animate_step(10000, step, function() { _this.end(); });
};

StepAnimation.prototype.end = function() {
  if (this.state_canvas) this.state_canvas.parentNode.removeChild(this.state_canvas);
  if (this.dot_canvas) this.dot_canvas.parentNode.removeChild(this.dot_canvas);

  for (var id in this.candidates) {
    var c = this.candidates[id];

    this.horse_race.candidates_up_to_now[id].n_delegates = c.end_n_delegates;

    var percent = 100 * c.end_n_delegates / this.horse_race.data.n_delegates_needed;
    c.els.n_delegates.textContent = format_int(c.end_n_delegates);
    c.els.marker.style.left = percent + '%';
  }
};

StepAnimation.prototype.skip_to_end = function() {
  this.cancel = true;
};

function HorseRace(div) {
  this.els = {
    div: div,
    play: div.querySelector('button.play')
  };

  this.data = JSON.parse(div.querySelector('.json-data').textContent);
  this.state_paths = JSON.parse(div.querySelector('.json-state-paths').textContent);
  this.step_number = this.data.race_days.length;

  var candidates_up_to_now = null;
  var candidate_els = this.candidate_els = {};

  Array.prototype.forEach.call(div.querySelectorAll('li.candidate-horse'), function(el) {
    var id = el.getAttribute('data-candidate-id');
    candidate_els[id] = {
      n_delegates: el.querySelector('.n-delegates'),
      marker: el.querySelector('.marker')
    };
  });

  Array.prototype.forEach.call(div.querySelectorAll('li.candidate-target'), function(el) {
    var id = el.getAttribute('data-candidate-id');
    candidate_els[id].target = el;
  });

  this.listen();
}

HorseRace.prototype.listen = function() {
  var _this = this;
  this.els.play.addEventListener('click', function() { _this.play(); });
};

HorseRace.prototype.play = function() {
  if (this.animation) {
    this.animation.skip_to_end();
    this.animation = null;
  }

  if (this.step_number == this.data.race_days.length) {
    this.reset();
  }

  this.step();
};

HorseRace.prototype.step = function() {
  var race_day = this.data.race_days[this.step_number];

  this.animation = new StepAnimation(this, this.step_number);
  this.animation.start();

  this.step_number += 1;
};

HorseRace.prototype.reset = function() {
  this.step_number = 0;
  this.candidates_up_to_now = {};

  for (var candidate_id in this.candidate_els) {
    var els = this.candidate_els[candidate_id];
    els.marker.style.left = '0';

    this.candidates_up_to_now[candidate_id] = {
      els: els,
      n_delegates: 0
    };
  }
};

function init_horse_races() {
  var divs = document.querySelectorAll('.horse-race');
  Array.prototype.forEach.call(divs, function(div) { new HorseRace(div); });
}

$.fn.horse_race = function() {
  return $(this).each(function() { new HorseRace(this); });
};
