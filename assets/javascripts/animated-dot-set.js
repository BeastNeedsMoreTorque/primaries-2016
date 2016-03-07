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
