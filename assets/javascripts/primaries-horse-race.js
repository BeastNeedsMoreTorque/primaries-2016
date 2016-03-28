var Split1 = '!';
var Split2 = '~';
var Split3 = '*';
var Split4 = '.';

/** Turns a JSON object into a compressed string. */
function encode_horse_race_data(json) {
  return [
    json.n_delegates,
    json.n_delegates_needed,
    json.candidates.map(function(c) { return [ c.id, c.n_delegates, c.n_unpledged_delegates ].join(Split3); }).join(Split2),
    json.race_days.map(function(rd) {
      var counts = {};
      rd.candidates.forEach(function(crd) { counts[crd.id] = crd.n_delegates });
      return rd.id + Split3 + rd.date_s + Split3 + json.candidates.map(function(c) {
        return counts[c.id] || 0;
      }).join(Split4)
    }).join(Split2),
    json.date_s || format_date(new Date())
  ].join(Split1);
}

/** Turns the result from encode_horse_race_data() into a JSON object. */
function decode_horse_race_data(s) {
  if (!s) return null;

  var arr = decodeURIComponent(s).split(Split1);

  var candidates = arr[2].split(Split2).map(function(cs) {
    var arr2 = cs.split(Split3);

    return {
      id: arr2[0],
      n_delegates: parseInt(arr2[1], 10),
      n_unpledged_delegates: parseInt(arr2[2], 10)
    };
  });

  var race_days = arr[3].split(Split2).map(function(rds) {
    var arr2 = rds.split(Split3);
    var arr3 = arr2[2].split(Split4);

    return {
      id: arr2[0],
      date_s: arr2[1],
      candidates: candidates.map(function(c, i) { return { id: c.id, n_delegates: parseInt(arr3[i], 10) }; })
    };
  });

  return {
    n_delegates: parseInt(arr[0], 10),
    n_delegates_needed: parseInt(arr[1], 10),
    candidates: candidates,
    race_days: race_days,
    date_s: arr[4] || format_date(new Date())
  };
}

/**
 * Changes the CSS classes of the race days to match the data.
 *
 * This is useful because the HTML is always _today's_ version of the calendar;
 * when people come to this page with a window.location.hash set, they want a
 * snapshot from a _prior_ day.
 */
function rearrange_race_days_for_data(data) {
  var unpledged = document.querySelector('div.horse-race ol.race-days li.unpledged-delegates');
  var ol = unpledged.parentNode;
  ol.removeChild(unpledged);

  Array.prototype.forEach.call(ol.childNodes, function(el, i) {
    if (i >= data.race_days.length) {
      el.classList.remove('has-delegates');
      el.classList.add('has-no-delegates');
    }
  });

  ol.insertBefore(unpledged, ol.querySelector('li.race-day.has-no-delegates'));
}

function show_embed_code_for_data(data) {
  var encoded = encode_horse_race_data(data);

  var id = 'elections-primaries-horse-race-' + window.location.pathname.split('/').pop();

  var $pre = $('<pre></pre>')
    .text('<div id="' + id + '"></div><script src="//elections.huffingtonpost.com/2016/javascripts/pym.min.js"></script><script>new pym.Parent("' + id + '", "//' + window.location.host + window.location.pathname + '#' + encodeURIComponent(encoded) + '");</script>');

  $('<div class="prompt-to-embed"></div>')
    .append('<p class="instructions">Hi, editor! Would you like to embed this interactive? Use this embed code:</p>')
    .append($pre)
    .append('<p class="instructions">Even when new races happen and the AP assigns more delegates, the embedded interactive will remain the way you see it now.</p>')
    .appendTo('body');
}

function format_date(date) {
  var Months = [ 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December' ];
  return Months[date.getMonth()] + ' ' + date.getDate();
}

$(function() {
  var data = decode_horse_race_data(location.hash.slice(1));

  if (data) {
    rearrange_race_days_for_data(data);
  } else {
    data = JSON.parse(document.querySelector('.json-data').textContent);
    data.date_s = format_date(new Date());
    show_embed_code_for_data(data);
  }

  var h1 = document.querySelector('h1');
  h1.textContent = h1.textContent + ', ' + data.date_s;

  var div = document.querySelector('div.horse-race');
  var horse_race = new HorseRace(div, data);
});
