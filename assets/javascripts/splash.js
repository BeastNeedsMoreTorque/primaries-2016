//= require './vendor/jquery-2.2.0.js'

$(function() {
  var iowa_starts = '2016-02-01 20:00:00 GMT'
  function timeTill(end) {
    var timeDifference = Date.parse(end) - Date.parse(new Date());
    return {
      'total': Date.parse(end) - Date.parse(new Date()),
      'days': Math.floor(timeDifference / (1000 * 60 * 60 * 24)),
      'hours': Math.floor((timeDifference / (1000 * 60 * 60)) % 24),
      'minutes': Math.floor((timeDifference / 1000 / 60) % 60),
      'seconds': Math.floor((timeDifference / 1000) % 60)
    };
  }
  function initClock(id, starttime){
    var countdown = document.getElementById(id);
    var hSpan = countdown.querySelector('.hours');
    var mSpan = countdown.querySelector('.minutes');
    var sSpan = countdown.querySelector('.seconds');
    function updateCountdown() {
      var time = timeTill(starttime);
      hSpan.innerHTML = time.hours;
      mSpan.innerHTML = ('0' + time.minutes).slice(-2);
      sSpan.innerHTML = ('0' + time.seconds).slice(-2);

      if(time.total <= 0) {
        clearInterval(timeinterval);
      }
    }
    updateCountdown();
    var timeinterval = setInterval(updateCountdown, 1000);
  }
  function fillSvg(data){
    document.getElementsByTagName("svg");
    var countiesReporting = 0;
    var totalPrecincts = 0;
    var precinctsReporting = 0;
    $(".counties").children().each(function(ele){
      fips = this.getAttribute("data-fips-int");
      obj = data[fips];
      totalPrecincts += obj["n_precincts_total"];
      precinctsReporting += obj["total_n_precincts_reporting"]
      if(obj["total_n_precincts_reporting"] > 0){
        countiesReporting++; 
        $(this).addClass("has-results");
      }
    });
    $("#counties-val").text(countiesReporting);
    $("#precincts-val").text(((precinctsReporting/totalPrecincts)*100).toFixed(0) + "%")
  }

  new pym.Child();
  $.getJSON(window.location.toString().split('#')[0] + '.json', function(json) {
    fillSvg(json);
  })
  .fail(function() { console.warn('Failed to load ' + json_url, this); })
  //.always(function() { window.setTimeout(poll_results, interval_ms); });


});
