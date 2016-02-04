$(function() {
  function fillSvg(data){
    var countiesReporting = 0;
    var totalPrecincts = 0;
    var precinctsReporting = 0;
    var totalCounties = $(".counties").children().length;
    $("svg .counties").children().each(function(ele){
      fips = this.getAttribute("data-fips-int");
      obj = data[fips];
      totalPrecincts += obj["n_precincts_total"];
      precinctsReporting += obj["total_n_precincts_reporting"];
      if(obj["total_n_precincts_reporting"] == obj["n_precincts_total"] && obj["total_n_precincts_reporting"] != 0){
        countiesReporting++; 
        $(this).addClass("has-results");
      }
    });
    var precinctsPct = ((precinctsReporting/totalPrecincts)*100).toFixed(0);
    if(precinctsPct > 99.0 && precinctsReporting != totalPrecincts){
      precinctsPct = "99%"
    }else{
      precinctsPct = precinctsPct + "%"
    }
    $("#unreported-counties").text(totalCounties - countiesReporting)
    $("#counties-val").html(countiesReporting + " FINISHED <span id='precincts-val'>(" + precinctsPct + " of precincts)</span>");
  }

  function updateCandidates(data, tense){
    $(".candidate table").removeClass("leader");
    for (key in data) {
      var candidates = data[key];
      $(".candidate[data-candidate-id="+candidates[0].id+"]").addClass("leader");

      data[key].forEach(function(item){
        $(".candidate[data-candidate-id="+item.id+"] .n-votes").text(format_int(item.n_votes));
      });  
    }
  }

  function getData(){
    $.getJSON('/2016/primaries/widget-results.json', function(json) {
      console.log(json);
      var tense = json["when_race_day_happens"];
      $("body").removeClass().addClass("race-day-" + tense);
      fillSvg(json["counties"]);
      updateCandidates(json["candidates"], tense);
    })
      .fail(function() { console.warn('Failed to load', this); })
      .always(function() { window.setTimeout(getData, 30000); });
  }

  console.log('HERE');
  $("svg").position_svg_cities();
  getData();
});
