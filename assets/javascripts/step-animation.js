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
    150 / 1000,
    0,
    0,
    150 / 1000,
    (i + 0.5) * w / n - 150 / 2,
    0
  ];
}

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

  this.animate_step(500, step, function() { _this.show_dots(); });
};

StepAnimation.prototype.show_dots = function() {
  var _this = this;

  function candidate_state_line(candidate_id, state_code, transform_matrix) {
    var line = DotLine.parse({ x: 0, y: 0 }, _this.horse_race.state_paths[state_code], transform_matrix);
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

  this.animate_step(3000, step, function() { _this.end(); });
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
