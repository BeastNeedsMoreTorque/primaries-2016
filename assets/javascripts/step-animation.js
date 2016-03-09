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
    70 / 1000,
    0,
    0,
    70 / 1000,
    (i + 0.5) * w / n - 70 / 2,
    50
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
  var h = 200;

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
  this.ended = false;

  var race_day = this.race_day = horse_race.data.race_days[step_number];

  var candidate_id_to_n_delegates = {};
  if (race_day) {
    race_day.candidates.forEach(function(c) {
      candidate_id_to_n_delegates[c.id] = c.n_delegates;
    });
  } else {
    horse_race.candidates.forEach(function(c) {
      candidate_id_to_n_delegates[c.id] = c.data.n_unpledged_delegates;
    });
  }

  horse_race.candidates.forEach(function(candidate) {
    candidate.n_delegates_start = candidate.n_delegates;
    candidate.n_delegates_end = candidate.n_delegates + (candidate_id_to_n_delegates[candidate.id] || 0);
  });

  this.candidates = horse_race.candidates;
}

StepAnimation.prototype.start = function() {
  if (this.race_day) {
    this.show_states();
  } else {
    this.add_unpledged_delegates();
  }
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
    if (_this.ended) return;

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

StepAnimation.prototype.add_unpledged_delegates = function() {
  var _this = this;

  function step(t) {
    _this.candidates.forEach(function(candidate) {
      var d = candidate.n_delegates_end - candidate.n_delegates_start;
      candidate.n_delegates = candidate.n_delegates_start + Math.round(d * t);
    });

    _this.horse_race.refresh_candidate_els();
  }

  this.animate_step(1000, step, function() { _this.end(); });
};

StepAnimation.prototype.show_states = function() {
  var _this = this;

  var canvas;

  function initialize() {
    var div = _this.horse_race.els.div;
    canvas = _this.state_canvas = build_canvas(div);

    var ctx = canvas.getContext('2d');

    var races = _this.race_day ? _this.race_day.races : [];
    var paths = _this.horse_race.state_paths;

    for (var i = 0; i < races.length; i++) {
      var race = races[i];

      ctx.save();

      var transform = build_race_transform_matrix(i, races.length, canvas.width);
      ctx.setTransform.apply(ctx, transform);

      draw_path(ctx, paths[race.state_code]);
      ctx.strokeStyle = 'blue';
      ctx.lineWidth = 5;
      ctx.stroke();

      ctx.restore();
    }
  }

  function step(t) {
    if (!canvas) { initialize(); }

    canvas.style.opacity = t;
    canvas.style.marginBottom = ((1 - Math.sqrt(t)) * -100) + 'px';
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

    var candidates = race.candidates
      .filter(function(c) { return c.n_delegates > 0; })
      .map(function(candidate) {
        var line = candidate_state_line(candidate.id, race.state_code, transform_matrix);
        return line ? { id: candidate.id, n_dots_remaining: candidate.n_delegates, line: line, dot_positions: [] } : null;
      })
      .filter(function(arr) { return !!arr; })
      ;

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
  var candidates_by_id = {};
  var candidate_dots; // Array[AnimatedDotSet]

  function initialize() {
    var div = _this.horse_race.els.div;
    canvas = _this.dot_canvas = build_canvas(div);
    width = canvas.width;
    ctx = canvas.getContext('2d');

    var races = _this.race_day.races;
    var partial_dot_sets = {}; // candidate_id -> Array of dots
    _this.candidates.forEach(function(c) { partial_dot_sets[c.id] = []; });

    for (var i = 0; i < races.length; i++) {
      var transform = build_race_transform_matrix(i, races.length, canvas.width);
      var race_dots = candidate_race_dots(races[i], transform);

      for (var j = 0; j < race_dots.length; j++) {
        var dots = race_dots[j];
        var arr = partial_dot_sets[dots.candidate_id];

        if (!arr) continue; // the candidate got delegates but we're not showing him/her in the horse race

        dots.dots.forEach(function(xy) {
          arr.push({
            x: xy.x * transform[0] + xy.y * transform[2] + transform[4],
            y: xy.x * transform[1] + xy.y * transform[3] + transform[5]
          });
        });
      }
    }

    var max_n_dots = _this.candidates.reduce(function(s, c) { var n = partial_dot_sets[c.id].length; return s > n ? s : n; }, 0);

    candidate_dots = _this.candidates.map(function(candidate) {
      var target_el = candidate.els.target;
      var target_xy = { x: target_el.offsetLeft + 37, y: 53 };
      var raw_dots = partial_dot_sets[candidate.id];

      return new AnimatedDotSet(candidate.id, target_xy, raw_dots, max_n_dots);
    });

    _this.candidates.forEach(function(candidate) {
      candidates_by_id[candidate.id] = candidate;
    });
  }

  function step(t) {
    if (!ctx) initialize();

    ctx.fillStyle = 'blue';
    ctx.beginPath();

    var radius = 3; // px

    candidate_dots.forEach(function(dot_set) {
      var dots = dot_set.get_dots_at(t);

      for (var j = 0; j < dots.length; j++) {
        var dot = dots[j];
        ctx.moveTo(dot.x, dot.y);
        ctx.arc(dot.x, dot.y, radius, 0, Math.PI * 2);
        ctx.closePath();
      }

      var n_complete = dot_set.get_n_dots_completed_at(t);
      var candidate = candidates_by_id[dot_set.candidate_id];
      candidate.n_delegates = candidate.n_delegates_start + n_complete;

      if (candidate.n_delegates == candidate.n_delegates_start) {
        candidate.swing_state = 'idle';
      } else if (candidate.n_delegates == candidate.n_delegates_end) {
        candidate.swing_state = 'settling';
      } else {
        candidate.swing_state = 'adding';
      }
    });

    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.fill();

    _this.state_canvas.style.opacity = Math.pow(1 - t, 2);
    _this.state_canvas.style.marginBottom = (Math.sqrt(t) * 20) + 'px';

    _this.horse_race.refresh_candidate_els();
  }

  var duration = this.race_day ? Math.sqrt(this.race_day.n_pledged_delegates) * 80 : 1000;
  this.animate_step(duration, step, function() { _this.end(); });
};

/**
 * Called at the end of animation. You may also call it at any time to abort
 * all further rendering.
 */
StepAnimation.prototype.end = function() {
  if (this.ended) return;
  this.ended = true;

  if (this.state_canvas) this.state_canvas.parentNode.removeChild(this.state_canvas);
  if (this.dot_canvas) this.dot_canvas.parentNode.removeChild(this.dot_canvas);

  this.candidates.forEach(function(candidate) {
    candidate.n_delegates = candidate.n_delegates_end;
    candidate.swing_state = 'idle';
  });

  this.horse_race.refresh_candidate_els();
};
