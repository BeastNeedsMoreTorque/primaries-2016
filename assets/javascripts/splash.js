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
    var precinctsPct = ((precinctsReporting/totalPrecincts)*100).toFixed(0) + "%";
    $("#unreported-counties").text(totalCounties - countiesReporting)
    $("#counties-val").html(countiesReporting + " FINISHED <span id='precincts-val'>(" + precinctsPct + " of precincts)</span>");
  }

  function updateCandidates(data){
    $(".candidate table").removeClass("leader");
    for(key in data){
      sorted = data[key].sort(function(a,b){return b[1] - a[1]})
      if(sorted[0][1] !== 0)
        $(".candidate[data-candidate-id='"+sorted[0][0]+"'] table").addClass("leader");
      sorted.forEach(function(item){
        $(".candidate[data-candidate-id='"+item[0]+"'] td:last-child").text(format_int(item[1]));
      });  
    }
  }

  function getData(){
    $.getJSON(window.location.toString().split('?')[0] + '.json', function(json) {
      fillSvg(json["counties"]);
      updateCandidates(json["candidates"]);
    })
    .fail(function() { console.warn('Failed to load', this); })
    .always(function() { window.setTimeout(getData, 30000); });
  }

  $("svg").position_svg_cities();
  getData();
});
