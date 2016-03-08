/**
 * A candidate and its group of dots.
 *
 * Each dot will animate from its start position to its end one.
 *
 * The animation is: we give each point its own Cubic Bézier curve. For each
 * frame we place each point along the line (with one `t` value, which makes the
 * math quick), but then we "pull" the closest points more quickly than the
 * farthest point, so they don't all complete at the same time. We time it such
 * that at t=0.5, the first point is already complete (so we're pulling them all
 * by half the distance to the closest one).
 */
function AnimatedDotSet(candidate_id, target_xy, dots) {
  this.candidate_id = candidate_id;
  this.target_xy = target_xy;
  this.dots = dots;

  this._scratch = this.dots.map(function(xy, i) {
    // Cubic Bézier curve
    // https://en.wikipedia.org/wiki/B%C3%A9zier_curve#Cubic_B.C3.A9zier_curves
    //
    // It's really hard to calculate curve length -- http://math.stackexchange.com/questions/12186/arc-length-of-b%C3%A9zier-curves
    // ... so we'll just assume dots which are further have longer curves. Heck,
    // that's probably even true.

    var dx = xy.x - target_xy.x;
    var dy = xy.y - target_xy.y;
    var d = Math.sqrt(dx * dx + dy * dy);

    return {
      x1: xy.x,
      y1: xy.y,
      x2: xy.x,
      y2: xy.y + - 100,
      x3: target_xy.x,
      y3: target_xy.y - 100 - i * 3,
      x4: target_xy.x,
      y4: target_xy.y,
      d: d
    };
  });
}

/**
 * Returns {x, y} Objects for time t, where t is between 0 and 1.
 *
 * At t=1, all dot positions are 
 */
AnimatedDotSet.prototype.get_dots_at = function(t) {
  if (this._last_get_dots_at && this._last_get_dots_at.t == t) {
    return this._last_get_dots_at.ret;
  }

  var scratch2 = [], i, p;

  var A = (1 - t) * (1 - t) * (1 - t);
  var B = 3 * (1 - t) * (1 - t) * t;
  var C = 3 * (1 - t) * t * t;
  var D = t * t * t;

  for (i = 0; i < this._scratch.length; i++) {
    p = this._scratch[i];
    var x = A * p.x1 + B * p.x2 + C * p.x3 + D * p.x4;
    var y = A * p.y1 + B * p.y2 + C * p.y3 + D * p.y4;
    var dx = p.x4 - x;
    var dy = p.y4 - y;

    scratch2.push({
      spline_x: x,
      spline_y: y,
      end_x: p.x4,
      end_y: p.y4,
      dx: dx,
      dy: dy,
      d: Math.sqrt(dx * dx + dy * dy)
    });
  }

  // We'll move every point towards x by the same amount
  var ds = scratch2.map(function(x) { return x.d; });
  var max_d = Math.max.apply(null, ds);
  var move_d = 2 * t * max_d;

  var ret = [];

  for (i = 0; i < scratch2.length; i++) {
    p = scratch2[i];

    if (p.d > move_d) {
      ret.push({
        x: p.spline_x + dx * move_d / p.d,
        y: p.spline_y + dy * move_d / p.d
      });
    }

    if (i == 0) {
      console.log(p, ret[ret.length - 1]);
    }
  }

  this._last_get_dots_at = {
    t: t,
    ret: ret
  };

  return ret;
};

/**
 * Returns number of dots that have disappeared by time t.
 */
AnimatedDotSet.prototype.get_n_dots_completed_at = function(t) {
  return this._scratch.length - this.get_dots_at(t).length;
};
