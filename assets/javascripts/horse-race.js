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
