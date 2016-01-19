//= require './vendor/jquery-2.2.0.js'

$.fn.render_time = function render_time() {
  this.each(function() {
    var datetime_string = this.getAttribute('datetime');
    if (!datetime_string) throw new Error('Tried to render_time() without a datetime attribute on element');

    var datetime = new Date(this.getAttribute('datetime'));
    if (isNaN(datetime.valueOf())) throw new Error('Invalid datetime string: ' + datetime_string);

    var hours = datetime.getHours();
    var minutes = datetime.getMinutes();
    var suffix = 'a.m.';
    if (hours >= 12) {
      hours -= 12;
      suffix = 'p.m.';
    }
    if (hours == 0) hours = 12;

    var hours_string = '' + hours;
    var minutes_string = '' + minutes;
    if (minutes_string.length == 1) minutes_string = '0' + minutes_string;

    $(this).text(hours_string + ':' + minutes_string + ' ' + suffix);
  });
};
