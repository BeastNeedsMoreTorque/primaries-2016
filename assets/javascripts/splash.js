$(function() {
  function fillSvg(data, precincts){
    var totalCounties = $(".counties").children().length;
    $("svg .counties").children().each(function(ele){
      fips = this.getAttribute("data-fips-int");
      obj = data[fips];
      if(obj["total_n_precincts_reporting"] == obj["n_precincts_total"] && obj["total_n_precincts_reporting"] != 0){
        $(this).addClass("has-results");
      }
    });
    $("#unreported-counties").text(precincts['counties_outstanding']);
    $("#counties-val").html(precincts['counties_finished'] + " FINISHED <span id='precincts-val'>(" + precincts['reporting_precincts_pct_str'] + " of precincts)</span>");
  }

  function updateCandidates(data, tense){
    $(".leader").removeClass("leader");

    for (key in data) {
      var candidates = data[key];
      if (candidates[0].n_votes) {
        $(".candidate[data-candidate-id="+candidates[0].id+"]").addClass("leader");
      }

      data[key].forEach(function(item){
        $(".candidate[data-candidate-id="+item.id+"] .n-votes").text(format_int(item.n_votes));
      });  
    }
  }

  function getData(){
    $.getJSON('/2016/primaries/widget-results.json', function(json) {
      var tense = json["when_race_day_happens"];
      $("body").removeClass().addClass("race-day-" + tense);
      fillSvg(json["counties"], json['precincts']);
      updateCandidates(json["candidates"], tense);
    })
      .fail(function() { console.warn('Failed to load', this); })
      .always(function() { window.setTimeout(getData, 30000); });
  }

  $("svg").position_svg_cities();
  getData();
});
