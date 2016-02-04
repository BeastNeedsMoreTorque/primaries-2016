$(function() {
  function updateCandidates(data, tense){
    $(".leader").removeClass("leader");
    for(key in data){
      sorted = data[key].sort(function(a,b){return b[1] - a[1]})
      if(sorted[0][1] !== 0 && tense !== 'future')
        $("tr[data-candidate-id='"+sorted[0][0]+"']").addClass("leader");
      sorted.forEach(function(item){
        $("tr[data-candidate-id='"+item[0]+"'] .n-votes").text(format_int(item[1]));
      });  
    }
  }

  function getData(){
    var url = window.location.protocol + "//" + window.location.host + "/2016/primaries/widget-results.json"
    $.getJSON(url, function(json) {
      tense = json["when_race_day_happens"];
      $("body").removeClass().addClass("race-day-" + tense);
      updateCandidates(json["candidates"], tense);
    })
    .fail(function() { console.warn('Failed to load', this); })
    .always(function() { window.setTimeout(getData, 30000); });
  }

  getData();
});
