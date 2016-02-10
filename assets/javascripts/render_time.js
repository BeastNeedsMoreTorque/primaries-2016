/**
 * Date -> "9:30 p.m." in the user's time zone.
 *
 * Useful for recent updates -- that is, from a few hours or minutes ago. A
 * relative string ("30 seconds ago") can be worse, because it will constantly
 * tick.
 */
function format_time(date) {
  var hours = date.getHours();
  var minutes = date.getMinutes();
  var suffix = 'a.m.';
  if (hours >= 12) {
    hours -= 12;
    suffix = 'p.m.';
  }
  if (hours == 0) hours = 12;

  var hours_string = '' + hours;
  var minutes_string = '' + minutes;
  if (minutes_string.length == 1) minutes_string = '0' + minutes_string;

  return hours_string + ':' + minutes_string + ' ' + suffix;
}

/**
 * Date -> "9:30 p.m.", "9:30 p.m. yesterday", "9:30 p.m. on Feb. 1",
 * "9:30 p.m. on Feb. 1, 2013".
 */
function format_datetime(date) {
  var now = new Date();
  var one_day_ago = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 1, 0, 0, 0);

  var time_string = format_time(date);
  var months = [ 'Jan.', 'Feb.', 'March', 'April', 'May', 'June', 'July', 'Aug.', 'Sept.', 'Oct.', 'Nov.', 'Dec.' ];
  var weekdays = [ 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' ];

  if (date.toDateString() == now.toDateString()) {
    return time_string;
  } else if (date > one_day_ago) {
    return time_string + ' yesterday';
  } else if (date.getFullYear() == now.getFullYear()) {
    return time_string + ' on ' + months[date.getMonth()] + ' ' + date.getDate();
  } else {
    return time_string + ' on ' + months[date.getMonth()] + ' ' + date.getDate() + ', ' + date.getFullYear();
  }
}

function extract_date(el) {
  var datetime_string = el.getAttribute('datetime');
  if (!datetime_string) return null; // nothing to render

  var date = new Date(datetime_string);
  if (isNaN(date.valueOf())) throw new Error('Invalid datetime string: ' + datetime_string);

  return date;
}

function render_time() {
  var date = extract_date(this);
  if (!date) return;
  var string = format_time(date);
  $(this).text(string);
}

function render_datetime() {
  var date = extract_date(this);
  if (!date) return;
  var string = format_datetime(date);
  $(this).text(string);
}

$.fn.render_time = function() {
  this.each(render_time);
};

$.fn.render_datetime = function() {
  this.each(render_datetime);
};
