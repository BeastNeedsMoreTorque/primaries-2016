$(function() {
  function updateCandidates(data, tense){
    $(".leader").removeClass("leader");
<<<<<<< HEAD
    for(party in data['candidates']){
      sorted = data['candidates'][party];
      leader = data['leader_' + party];
      if(tense !== 'future')
        $("tr[data-candidate-id='"+leader+"']").addClass("leader");
      for(candidate_id in sorted){
        candidate = sorted[candidate_id];
        $("tr[data-candidate-id='"+candidate_id+"'] .n-votes").text(format_int(candidate.votes));
      }
=======

    for (party_id in data) {
      var candidates = data[party_id];
      if (candidates[0].n_votes) {
        $('tr[data-candidate-id=' + candidates[0].id + ']').addClass('leader');
      }

      candidates.forEach(function(candidate){
        $("tr[data-candidate-id="+candidate.id+"] .n-votes").text(format_int(candidate.n_votes));
      });  
>>>>>>> master
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
