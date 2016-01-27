//= require './vendor/jquery-2.2.0.js'
//= require './render_time.js'

$(function() {
  $('.last-updated').render_datetime();

  $('.day-count').text(function () {
    var now = new Date();
    var iowa_date = new Date('01 February, 2016');
    var time_left = Math.ceil((iowa_date - now) / 1000 / 60 / 60 / 24);
    if (time_left > 1) {
      return 'In ' + time_left + ' days';
    } else if (time_left === 1) {
      return 'In ' + time_left + ' day';
    } else {
      return 'Today';
    }
  });

  $(document).on('click', function(ev) {
    window.location = $('body').attr('data-race-day-href');
  });
});
