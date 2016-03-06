$(function() {
  function update_race_from_json($race, race_json) {
    var candidate_id_to_tr_and_position = {}; // { candidate_id -> { tr: HTMLElement, position: 3 } }
    $race.find('tr[data-candidate-id]').each(function(i) {
      candidate_id_to_tr_and_position[this.getAttribute('data-candidate-id')] = { tr: this, position: i };
    });
    var need_reorder = false;

    race_json.candidates.forEach(function(candidate_json, i) {
      var o = candidate_id_to_tr_and_position[candidate_json.id];
      if (!o) return;
      var tr = o.tr;

      if (o.position != i) {
        need_reorder = true;
      }

      if (need_reorder) {
        tr.parentNode.appendChild(tr);
        // and need_reorder stays true, so every subsequent row will be moved
        // to the end of the table while we iterate.
      }

      var class_name = '';
      if (candidate_json.leader) {
        class_name += ' leader';
      }
      if (candidate_json.winner) {
        class_name += ' winner';
      }

      tr.setAttribute('class', class_name);
      $('.n-votes', tr).text(format_int(candidate_json.n_votes || 0));
      $('.n-votes-pct', tr).text(format_percent(candidate_json.percent_vote || 0));
    });
  }

  function update_races_from_json(json) {
    json.races.forEach(function(race_json) {
      var $race = $('#' + race_json.id);
      update_race_from_json($race, race_json);
    });
  }

  function getData(){
    $.getJSON('/2016/primaries/widget-results.json', function(json) {
      tense = json["when_race_day_happens"];
      $("body").removeClass().addClass("race-day-" + tense);
      update_races_from_json(json);
    })
      .fail(function() { console.warn('Failed to load', this); })
      .always(function() { window.setTimeout(getData, 30000); });
  }

  $('.few-races').each(getData); // Only do it for few-races
});
