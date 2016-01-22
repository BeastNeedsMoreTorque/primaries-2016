//= require './vendor/jquery-2.2.0.js'

$(function() {
  var iowa_polls_close = new Date('2/2/2016 1:00:00 AM UTC');
  function timeTill(end) {
    var timeDifference = Date.parse(end) - Date.parse(new Date());

    if(timeDifference > 0){
      $(".countdown-container h3").text("POLLS CLOSE IN")
    }else {
      $(".countdown-container h3").text("POLLS CLOSED FOR")
      timeDifference = Date.parse(new Date()) - Date.parse(end);
    }

    return {
      'total': timeDifference,
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
    var totalCounties = $(".counties").children().length;
    $(".counties").children().each(function(ele){
      fips = this.getAttribute("data-fips-int");
      obj = data[fips];
      totalPrecincts += obj["n_precincts_total"];
      precinctsReporting += obj["total_n_precincts_reporting"]
      if(obj["total_n_precincts_reporting"] == obj["n_precincts_total"]){
        countiesReporting++; 
        $(this).addClass("has-results");
      }
    });
    $("#unreported-counties").text(totalCounties - countiesReporting)
    $("#counties-val").text(countiesReporting);
    //$("#precincts-val").text(((precinctsReporting/totalPrecincts)*100).toFixed(0) + "%")
  }
  initClock("countdown", iowa_polls_close);
  new pym.Child();
  $.getJSON(window.location.toString().split('#')[0] + '.json', function(json) {
    fillSvg(json);
  })
  .fail(function() { console.warn('Failed to load ' + json_url, this); })
  //.always(function() { window.setTimeout(poll_results, interval_ms); });


});
