$(function() {
  function updateCandidates(data, tense){
    $(".leader").removeClass("leader");
    for(party in data['candidates']){
      sorted = data.candidates[party];
      leader = data.leaders[party];
      if(tense !== 'future')
        $("tr[data-candidate-id='"+leader.id+"']").addClass("leader");
      for(candidate_id in sorted){
        candidate = sorted[candidate_id];
        console.log(candidate, $("tr[data-candidate-id='"+candidate_id+"'] .n-votes"))
        $("tr[data-candidate-id='"+candidate.id+"'] .n-votes").text(format_int(candidate.votes || 0));
        $("tr[data-candidate-id='"+candidate.id+"'] .n-votes-pct").text(format_percent(candidate.pct || 0));
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
