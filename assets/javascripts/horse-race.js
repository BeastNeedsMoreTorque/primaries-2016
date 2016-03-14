function index_objects_by(array, property) {
  var ret = {};
  for (var i = 0; i < array.length; i++) {
    var object = array[i];
    var key = object[property];
    ret[key] = object;
  }
  return ret;
}

function HorseRace(div) {
  this.els = {
    div: div,
    bar_label: div.querySelector('.bar-label'),
    race_days: div.querySelector('ol.race-days'),
    race_day_left: div.querySelector('.race-day-selector .left'),
    race_day_right: div.querySelector('.race-day-selector .right'),
    button: div.querySelector('button')
  };

  this.playing = false;
  this.loading = true;

  this.data = JSON.parse(div.querySelector('.json-data').textContent);

  var state_paths = this.state_paths = {}; // state-code -> svg path "d"
  Array.prototype.forEach.call(div.querySelectorAll('li.race'), function(el) {
    var state_code = el.getAttribute('data-state-code');
    var path = el.querySelector('path');
    state_paths[state_code] = path.getAttribute('d');
  });

  var data_by_candidate_id = index_objects_by(this.data.candidates, 'id');
  var candidates_by_id = this.candidates_by_id = {};

  Array.prototype.forEach.call(div.querySelectorAll('li.candidate-horse'), function(el) {
    var id = el.getAttribute('data-candidate-id');
    var data = data_by_candidate_id[id];
    candidates_by_id[id] = {
      id: id,
      els: {
        row: el,
        marker: el.querySelector('.marker'),
        speech_bubble: el.querySelector('.speech-bubble')
      },
      data: data,
      slug: data.slug,
      n_delegates: data.n_delegates, // When we animate, this property will animate
      speech_bubble_html: null,      // While adding, there's sometimes a speech bubble
      animation_state: 'idle'        // When we animate, it'll go 'idle' -> 'adding' -> 'idle'
    };
  });

  Array.prototype.forEach.call(div.querySelectorAll('li.candidate-target'), function(el) {
    var id = el.getAttribute('data-candidate-id');
    var els = candidates_by_id[id].els;
    els.n_delegates = el.querySelector('.n-delegates');
    els.target = el;
  });

  this.candidates = this.data.candidates.map(function(c) { return candidates_by_id[c.id]; });

  this.load_steps();
  this.set_bar_background_positions();

  /**
   * step_position: where we are in time.
   *
   * Step positions are in between two steps. Position 0 is _before_ step 0;
   * position 1 is _before_ step 1.
   */
  this.step_position = this.steps.length;

  this.listen();

  this.refresh();

  this.loading = false;
  div.classList.remove('loading');
}

HorseRace.prototype.set_bar_background_positions = function() {
  Array.prototype.forEach.call(this.els.div.querySelectorAll('ul.bars li'), function(li) {
    // background-position is _old-school_. It's really hard to use percentages.
    // We know that each "wave" is twice as wide as it is tall; so we can
    // calculate how many "waves" have passed before this <li> starts, and align
    // the image that way.
    var h = li.offsetHeight;

    if (h > 0) {
      var waveWidth = 2 * h;
      var left = li.offsetLeft;
      var nWaves = left / waveWidth;
      var fractionAlongThisWave = nWaves % 1;
      li.style.backgroundPosition = 'left -' + (fractionAlongThisWave * waveWidth) + 'px top 1px';
    }
  });
};

/**
 * Sets this.steps to an Array of HorseRaceSteps.
 */
HorseRace.prototype.load_steps = function() {
  var steps = this.steps = [];

  var _this = this;

  var current_candidates = {};
  this.candidates.forEach(function(c) {
    current_candidates[c.id] = { n_delegates_end: 0 };
    var els = _this.candidates_by_id[c.id].els;

    els.bars = document.createElement('ul');
    els.bars.className = 'bars';
    els.row.appendChild(els.bars);
  });

  this.data.race_days.forEach(function(rd, i) {
    // Add bars behind the horses for each step.
    rd.candidates.forEach(function(rdc) {
      var els = _this.candidates_by_id[rdc.id].els;
      var bar = document.createElement('li');
      bar.style.width = 100 * rdc.n_delegates / _this.data.n_delegates_needed + '%';
      els.bars.appendChild(bar);
    });

    var step = new HorseRaceStep(i, 'race-day', 'Delegates won ' + rd.date_s, current_candidates, rd.candidates);
    steps.push(step);
    current_candidates = step.candidate_n_delegates_map;
  });

  if (this.data.candidates.some(function(c) { return c.n_unpledged_delegates > 0; })) {
    var step_candidates = [];

    this.data.candidates.forEach(function(c) {
      step_candidates.push({ id: c.id, n_delegates: c.n_unpledged_delegates });
      var els = _this.candidates_by_id[c.id].els;
      var bar = document.createElement('li');
      bar.style.width = 100 * c.n_unpledged_delegates / _this.data.n_delegates_needed + '%';
      els.bars.appendChild(bar);
    });

    steps.push(new HorseRaceStep(steps.length, 'unpledged', 'Superdelegates', current_candidates, step_candidates));
  }
};

HorseRace.prototype.on_calendar_mousedown = function(ev) {
  function event_to_xy(e) {
    if (e.changedTouches) {
      var touch = e.changedTouches[0];
      return { x: touch.clientX, y: touch.clientY };
    } else {
      return { x: e.clientX, y: e.clientY };
    }
  }

  if (this.touching) return;
  this.touching = true;

  this.pause();

  var _this = this;
  var race_day_el = ev.currentTarget;
  var scroll_left = race_day_el.scrollLeft;
  var start_xy = event_to_xy(ev);
  var DragThresholdSquared = 36; // square of number of pixels movement to indicate we're dragging
  var dragging = false; // false if we move our mouse far enough

  function maybe_reposition_calendar(ev2) {
    var end_xy = event_to_xy(ev2);
    var dx = end_xy.x - start_xy.x;

    if (!dragging && dx * dx > DragThresholdSquared) {
      dragging = true;
    }

    if (dragging) {
      race_day_el.scrollLeft = scroll_left - dx;
    }
  };

  function jump_to_centered_race_day() {
    var offset_x = race_day_el.scrollLeft + race_day_el.clientWidth / 2;

    for (var i = 0; i < race_day_el.childNodes.length; i++) {
      var li = race_day_el.childNodes[i]; // Assume no whitespace between <li>s
      if (li.offsetLeft + li.offsetWidth > offset_x) {
        _this.set_step_position(Math.min(_this.steps.length, i + 1));
        return;
      }
    }
  }

  function jump_to_clicked_race_day(e) {
    var node = e.target;
    while (node.parentNode != document && !node.classList.contains('race-day') && !node.classList.contains('unpledged-delegates')) {
      node = node.parentNode;
    }

    if (node) {
      var index = Array.prototype.indexOf.call(node.parentNode.childNodes, node);
      if (index != -1) {
        _this.set_step_position(Math.min(_this.steps.length, index + 1));
      }
    }
  };

  function on_mouseup(ev2) {
    document.removeEventListener('mousemove', maybe_reposition_calendar);
    document.removeEventListener('mouseup', on_mouseup);
    document.removeEventListener('touchmove', maybe_reposition_calendar);
    document.removeEventListener('touchend', on_mouseup);

    _this.touching = false;

    if (dragging) {
      maybe_reposition_calendar(ev2);
      jump_to_centered_race_day();
    } else {
      if (ev2.target.tagName == 'A') {
        // do nothing. Let the browser treat it as a normal click
      } else {
        jump_to_clicked_race_day(ev2);
      }
    }
  }

  document.addEventListener('mousemove', maybe_reposition_calendar);
  document.addEventListener('mouseup', on_mouseup);
  document.addEventListener('touchmove', maybe_reposition_calendar);
  document.addEventListener('touchend', on_mouseup);

  if (ev.target.tagName != 'A') {
    ev.preventDefault(); // avoid dragging/selecting
  }
};

HorseRace.prototype.listen = function() {
  var _this = this;

  this.els.button.addEventListener('click', function(ev) {
    if (window.ga) {
      window.ga('send', 'event', 'horse-race', ev.currentTarget.className);
    }

    if (ev.currentTarget.className == 'play') {
      _this.play();
      ev.currentTarget.className = 'pause';
    } else {
      _this.pause();
      ev.currentTarget.className = 'play';
    }
  });

  this.els.race_days.addEventListener('mousedown', function(ev) { _this.on_calendar_mousedown(ev); });
  this.els.race_days.addEventListener('touchstart', function(ev) { _this.on_calendar_mousedown(ev); });

  window.addEventListener('resize', function() {
    _this.refresh();
    _this.set_bar_background_positions();
  });
};

/**
 * Moves us to the given step position.
 *
 * Only call this when we aren't animating.
 */
HorseRace.prototype.set_step_position = function(step_position) {
  this.step_position = step_position;

  if (step_position === this.steps.length) {
    var last_step = this.steps[this.steps.length - 1];
    this.candidates.forEach(function(c) {
      c.n_delegates = last_step.candidate_n_delegates_map[c.id].n_delegates_end;
    });
  } else {
    var step = this.steps[step_position];
    this.candidates.forEach(function(c) {
      c.n_delegates = step.candidate_n_delegates_map[c.id].n_delegates_start;
    });
  }

  this.refresh();
};

HorseRace.prototype.play = function() {
  if (this.animation) return;
  if (this.playing) throw new Error('How are we playing if there is no animation?');

  this.playing = true;
  this.els.button.className = 'pause';
  $(this.els.div).addClass('animating');

  if (this.step_position == this.steps.length) {
    this.set_step_position(0);
  } else {
    this.refresh_active_race_day();
  }

  this.play_step();
};

HorseRace.prototype.on_step_end = function() {
  this.animation = null;

  if (!this.playing) {
    // User clicked to stop animating
    this.set_step_position(this.step_position + 1);
  } else if (this.step_position === this.steps.length - 1) {
    this.pause();
    // Set step position after pause, so refresh_active_race_day keeps us on the
    // correct <li>. (See comments about li_index.)
    this.set_step_position(this.step_position + 1);
  } else {
    this.set_step_position(this.step_position + 1);
    this.play_step();
  }
};

HorseRace.prototype.pause = function() {
  this.playing = false;

  if (this.animation) {
    this.animation.end();
  }

  $(this.els.div).removeClass('animating');
  this.els.button.className = 'play';
};

HorseRace.prototype.refresh = function() {
  this.refresh_active_race_day();
  this.refresh_candidate_els();
};

HorseRace.prototype.refresh_active_race_day = function() {
  var race_days_el = this.els.race_days;
  $(race_days_el).children().removeClass('active after-active before-active');

  // If we're playing starting at position 2, highlight li #2
  // If we *clicked* on li #2, we're at position 3; highlight li #2
  var li_index = this.playing ? this.step_position : Math.max(0, this.step_position - 1);

  var $active_li = $(race_days_el).children().eq(li_index);
  
  $active_li.addClass('active');
  $active_li.prevAll().addClass('before-active');
  $active_li.nextAll().addClass('after-active');
  var active_li = $active_li.get(0);
  var race_day_left = active_li.offsetLeft;
  var left = Math.floor(race_day_left + active_li.getBoundingClientRect().width * 0.5 - race_days_el.getBoundingClientRect().width * 0.5);
  $(race_days_el).stop(true);
  if (!this.loading) {
    $(race_days_el).animate({ scrollLeft: left }, { duration: 200 });
  } else {
    race_days_el.scrollLeft = left;
  }

  this.els.race_day_left.style.width = Math.max(0, race_day_left - left) + 'px';
  this.els.race_day_right.style.width = Math.max(0, race_days_el.clientWidth - race_day_left + left - active_li.getBoundingClientRect().width) + 'px';

  var bar_label = this.els.bar_label;
  var bar = this.candidates[this.candidates.length - 1].els.bars.childNodes[li_index];
  var bar_left = (bar.offsetLeft + bar.offsetWidth / 2) / bar.parentNode.offsetWidth;

  if (bar.offsetWidth < 3) {
    bar_label.classList.add('too-small');
  } else {
    bar_label.classList.remove('too-small');
    bar_label.innerText = this.steps[li_index].label;
    if (bar_left < 0.5) {
      bar_label.style.left = 100 * bar_left + '%';
      bar_label.style.right = 'auto';
      bar_label.classList.add('anchor-left');
      bar_label.classList.remove('anchor-right');
    } else {
      bar_label.style.left = 'auto';
      bar_label.style.right = 100 * (1 - bar_left) + '%';
      bar_label.classList.remove('anchor-left');
      bar_label.classList.add('anchor-right');
    }
  }
};

HorseRace.prototype.build_candidate_speech_bubble = function(candidate, max_n_delegates) {
  var in_past = this.step_position < this.steps.length;

  if (candidate.speech_bubble_html) {
    return candidate.speech_bubble_html; // "Yee-haw!", etc.
  } else if (candidate.n_delegates >= this.data.n_delegates_needed) {
    return "I'm the presumptive nominee!";
  } else if (candidate.n_delegates == max_n_delegates) {
    var n_remaining = this.data.n_delegates_needed - candidate.n_delegates;
    return 'I ' + (in_past ? 'needed' : 'need') + ' <strong>' + format_int(n_remaining) + ' more ' + (n_remaining > 1 ? 'delegates' : 'delegate') + '</strong>';
  } else {
    var n_behind = max_n_delegates - candidate.n_delegates;
    return 'I' + (in_past ? ' was' : "'m") + ' behind by <strong>' + format_int(n_behind) + ' ' + (n_behind > 1 ? 'delegates' : 'delegate') + '</strong>';
  }
};

HorseRace.prototype.refresh_candidate_els = function() {
  var _this = this;

  var n_delegates_needed = this.data.n_delegates_needed;
  var max_n_delegates = this.candidates.reduce(function(max, c) { return c.n_delegates > max ? c.n_delegates : max; }, 0);

  this.candidates.forEach(function(candidate) {
    var left = Math.min(1, candidate.n_delegates / n_delegates_needed);
    candidate.els.marker.style.left = (100 * left) + '%';
    candidate.els.speech_bubble.innerHTML = _this.build_candidate_speech_bubble(candidate, max_n_delegates);
    candidate.els.n_delegates.innerText = format_int(candidate.n_delegates);

    candidate.els.row.className = 'candidate-horse ' + candidate.animation_state;
    candidate.els.marker.className = 'marker ' + candidate.animation_state + (candidate.speech_bubble_html ? ' force-speech-bubble' : '');
    candidate.els.target.className = 'candidate-target ' + candidate.animation_state;

    $(candidate.els.bars).children()
      .removeClass('current-step')
      .eq(Math.max(0, _this.step_position - 1)).addClass('current-step');
  });
};

HorseRace.prototype.play_step = function() {
  this.animation = new StepAnimation(this, this.steps[this.step_position]);
  this.animation.start();
};

function init_horse_races() {
  var divs = document.querySelectorAll('.horse-race');
  Array.prototype.forEach.call(divs, function(div) { new HorseRace(div); });
}

$.fn.horse_race = function() {
  return $(this).each(function() { new HorseRace(this); });
};
