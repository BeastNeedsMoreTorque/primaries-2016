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
 *
 * @param candidate_id Candidate ID String
 * @param target_xy { x, y } in the <canvas> where all these dots will go
 * @param dots Array of { x, y } dot start positions
 * @param max_n_dots Maximum `dots.length` across all candidates. We use this
 *                   so a candidate with fewer dots will complete its animation
 *                   before t=1; the "winner" animates longer than the "losers"
 */
function AnimatedDotSet(candidate_id, target_xy, dots, max_n_dots) {
  this.candidate_id = candidate_id;
  this.target_xy = target_xy;
  this.dots = dots;
  this.max_n_dots = max_n_dots;
  this.is_winner = dots.length == max_n_dots;

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

  this._scratch.sort(function(p1, p2) { return p1.d - p2.d; });
}

/**
 * Returns {x, y} Objects for time t, where t is between 0 and 1.
 *
 * At t=0.1000001, each candidate's first dot will complete.
 * At t=1, returns the empty Array: all objects have finished their animation.
 */
AnimatedDotSet.prototype.get_dots_at = function(t) {
  if (this._last_get_dots_at && this._last_get_dots_at.t == t) {
    return this._last_get_dots_at.ret;
  }

  var n_dots_in, dot_t;
  var NoDotsT = 0.2;
  var Damping = 0.9; // so we can see dots going to Trump from far left

  var ret = [];

  // Number of dots in at time t, t >= NoDotsT:
  // n_dots_in = max_n_dots * (t - NoDotsT) / (1 - NoDotsT)
  //
  // ... which lets us calculate that time n dots will be in:
  // t = NoDotsT + n_dots_in * (1 - NoDotsT) / max_n_dots

  if (t < NoDotsT) {
    n_dots_in = 0;
    dot_t = t / NoDotsT;
  } else {
    var n_dots_in_real = (t - NoDotsT) / (1 - NoDotsT) * this.max_n_dots;
    n_dots_in = Math.floor(n_dots_in_real);

    // Calculate how far towards the destination our next dot should be.
    var last_dot_t = NoDotsT + n_dots_in * (1 - NoDotsT) / this.max_n_dots;
    var next_dot_t = NoDotsT + (n_dots_in + 1) * (1 - NoDotsT) / this.max_n_dots;

    // Okay, so I'm not so sure of myself here. But I think this is okay.
    //
    // The possible values:
    //
    // * t / next_dot_t: how far along we are to the next dot going in.
    //   Rationale: if t =~ next_dot_t, we want that dot to be very close to
    //   its destination.
    // * t / last_dot_t * Damping: how far along the previous dot was at a `t`
    //   very close to this one.
    //   Rationale: if t =~ last_dot_t, we don't want dot_t to be _lower_ for
    //   the next dot than it was in a previous frame.
    // * 1: maximum `dot_t`.
    //   Rationale: `t / last_dot_t * Damping` might be > 1.
    //
    // It's possible for this function to "jitter". That's okay -- we're
    // simulating a smooth animation curve (really slow to compute) with very
    // cheap math.
    dot_t = Math.max(Math.min(1, t / last_dot_t * Damping), t / next_dot_t);
  }

  this._scratch.forEach(function(p, i) {
    if (i < n_dots_in) {
      // Hide the dot
    } else {
      ret.push({
        x: p.x - p.dx * Math.sqrt(dot_t),
        y: p.y - p.dy * dot_t
      });
      dot_t *= Damping;
    }
  });

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
