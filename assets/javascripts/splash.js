//= require './vendor/jquery-2.2.0.js'
//= require './format_int.js'
//= require './position_svg_cities.js'
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
      precinctsPct = precinctsPct.toFixed(0) + "%"
    }

    $("#unreported-counties").text(totalCounties - countiesReporting)
    $("#counties-val").html(countiesReporting + " FINISHED <span id='precincts-val'>(" + precinctsPct + " of precincts)</span>");
  }

  function updateCandidates(data, tense){
    $(".candidate table").removeClass("leader");
    for(key in data){
      sorted = data[key].sort(function(a,b){return b[1] - a[1]})
      if(sorted[0][1] !== 0 && tense !== 'future')
        $(".candidate[data-candidate-id='"+sorted[0][0]+"'] table").addClass("leader");
      sorted.forEach(function(item){
        $(".candidate[data-candidate-id='"+item[0]+"'] td:last-child").text(format_int(item[1]));
      });  
    }
  }

  function getData(){
    var url = window.location.protocol + "//" + window.location.host + "/2016/primaries/widget-results.json"
    $.getJSON(url, function(json) {
      tense = json["when_race_day_happens"];
      $("body").removeClass().addClass("race-day-" + tense);
      fillSvg(json["counties"]);
      updateCandidates(json["candidates"], tense);
    })
    .fail(function() { console.warn('Failed to load', this); })
    .always(function() { window.setTimeout(getData, 30000); });
  }

  $("svg").position_svg_cities();
  getData();
});
