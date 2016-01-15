//= require './vendor/jquery-2.2.0.js'
$(function() {
  var iowa_starts = '2016-02-01'
  function timeTillIowa(end) {
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
    var dSpan = countdown.querySelector('.days');
    var hSpan = countdown.querySelector('.hours');
    var mSpan = countdown.querySelector('.minutes');
    var sSpan = countdown.querySelector('.seconds');
    function updateCountdown() {
      debugger;
      var time = timeTillIowa(starttime);
      dSpan.innerHTML = time.days;
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
  initClock('countdown', iowa_starts);
});
