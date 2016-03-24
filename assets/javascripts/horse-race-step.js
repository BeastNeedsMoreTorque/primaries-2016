function HorseRaceStep(step_number, type, label, previous_step_candidate_n_delegates_map, this_step_candidates_array) {
  this.step_number = step_number; // first step is number 0
  this.type = type;
  this.label = label;

  var m = this.candidate_n_delegates_map = {};
  var n_delegates = 0;
  var max_n_delegates = 0;

  var seen_candidate_ids = {};

  this_step_candidates_array.forEach(function(c) {
    var n_delegates_start = previous_step_candidate_n_delegates_map[c.id].n_delegates_end;
    seen_candidate_ids[c.id] = null;

    m[c.id] = {
      n_delegates: c.n_delegates,
      n_delegates_start: n_delegates_start,
      n_delegates_end: n_delegates_start + c.n_delegates
    };

    n_delegates += c.n_delegates;

    if (c.n_delegates > max_n_delegates) {
      max_n_delegates = c.n_delegates;
    }
  });

  // Candidates who dropped out of the race need zeroes
  for (var id in previous_step_candidate_n_delegates_map) {
    if (!seen_candidate_ids.hasOwnProperty(id)) {
      var n_delegates_start = previous_step_candidate_n_delegates_map[id].n_delegates_end;

      m[id] = {
        n_delegates: 0,
        n_delegates_start: n_delegates_start,
        n_delegates_end: n_delegates_start
      };
    }
  }

  this.n_delegates = n_delegates;
  this.max_candidate_n_delegates = max_n_delegates;
}
