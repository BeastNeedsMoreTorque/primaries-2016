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

  var no_dots_t = 0.1; // fraction of animation before first dot completes

  this._scratch = this.dots.map(function(xy, i) {
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

  this._scratch.forEach(function(p, i) {
    p.max_t = no_dots_t + (1 - no_dots_t) * (i + 1) / max_n_dots
  });
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


  var n_dots_complete = 0;
  var ret = [];

  var max_n_dots = this.max_n_dots;

  this._scratch.forEach(function(p, i) {

    if (t > p.max_t) {
      n_dots_complete += 1;
    } else {
      var u = 1 - Math.pow((p.max_t - t) / p.max_t, .25);
      ret.push({
        x: p.x - u * p.dx,
        y: p.y - u * p.dy
      });
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
