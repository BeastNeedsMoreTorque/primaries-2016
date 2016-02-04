//= require './vendor/jquery-2.2.0.js'
$(function() {
  function getData(){
    var url = window.location.protocol + "//" + window.location.host + "/2016/primaries/widget-results.json"
    $.getJSON(url, function(json) {
      var precincts = json['precincts']
      $("#precincts-val").html(precincts['reporting_precincts_pct_str']);
    })
    .fail(function() { console.warn('Failed to load', this); });
  }
  getData();
});
