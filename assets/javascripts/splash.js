//= require './vendor/jquery-2.2.0.js'
//= require './wait_for_font_then.js'
//= require './position_svg_cities.js'
$(function() {
  new pym.Child();

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
    $("#counties-val").html(countiesReporting + " FINISHED <span id='precincts-val'>(" + precinctsPct + " OF PRECINCTS)</span>");
  }

  wait_for_font_then("Source Sans Pro", function(){
    $("svg").position_svg_cities();

    $.getJSON(window.location.toString().split('?')[0] + '.json', function(json) {
      fillSvg(json);
    })
      .fail(function() { console.warn('Failed to load', this); })
      //.always(function() { window.setTimeout(poll_results, interval_ms); });
  });
});
