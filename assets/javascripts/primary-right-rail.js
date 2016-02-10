$(function() {
  function updateCandidates(data, tense){
    $(".leader").removeClass("leader");
    $('.winner').removeClass('winner');

    for (var party in data['candidates']) {
      var sorted = data.candidates[party];
      var leader = data.leaders[party];

      if(tense !== 'future') {
        $("tr[data-candidate-id='"+leader.id+"']").addClass("leader");
      }

      for (var i in sorted) {
        var candidate = sorted[i];
        var $tr = $('tr[data-candidate-id=' + candidate.id + ']);
        $tr.find('.n-votes').text(format_int(candidate.votes || 0));
        $tr.find('.n-votes-pct').text(format_int(candidate.pct || 0));
        $tr.toggleClass('winner', candidate.winner);
      }
    }
  }

  function getData(){
    $.getJSON('/2016/primaries/widget-results.json', function(json) {
      tense = json["when_race_day_happens"];
      $("body").removeClass().addClass("race-day-" + tense);
      updateCandidates(json["candidates"], tense);
    })
      .fail(function() { console.warn('Failed to load', this); })
      .always(function() { window.setTimeout(getData, 30000); });
  }

  getData();
});
