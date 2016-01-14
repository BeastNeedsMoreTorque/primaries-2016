$(function() {
  var $table = $('.state-race-days table');
  var tbody = $table.find('tbody')[0];

  var $th_state = $table.find('th.state');
  var $th_date = $table.find('th.date');

  var trs = [];
  $table.find('tbody tr').each(function() {
    trs.push({
      tr: this,
      $date: $('td.date', this),
      $state: $('td.state', this),
      date: this.getAttribute('data-race-day'),
      state: this.getAttribute('data-state-name'),
      party: this.getAttribute('data-party-name')
    });
  });

  var cmp = {
    by_date: function(a, b) {
      if (a.date != b.date) {
        return a.date < b.date ? -1 : 1;
      } else if (a.state != b.state) {
        return a.state < b.state ? -1 : 1;
      } else {
        return a.party < b.party ? -1 : 1;
      }
    },
    by_state: function(a, b) {
      if (a.state != b.state) {
        return a.state < b.state ? -1 : 1;
      } else if (a.date != b.date) {
        return a.date < b.date ? -1 : 1;
      } else {
        return a.party < b.party ? -1 : 1;
      }
    }
  };

  /** Sets ".repeated" on any <td> that has the same value as the one above.
    *
    * Applies to "date" _or_ "state".
    */
  function refresh_repeated_class(name) {
    $table.find('.repeated').removeClass('repeated');
    $table.find('.no-repeated').removeClass('no-repeated');

    var property = '$' + name;
    var attribute = {
      date: 'data-race-day',
      state: 'data-state-name'
    }[name];

    var last_value = null;

    trs.forEach(function(tr) {
      var current_value = tr.tr.getAttribute(attribute);

      if (current_value != last_value) {
        last_value = current_value;
        $(tr.tr).addClass('no-repeated');
      } else {
        tr[property].addClass('repeated');
      }
    });
  }

  function resort_trs(by) {
    var comparator = cmp['by_' + by];
    trs.sort(comparator);

    trs.forEach(function(tr) {
      tbody.appendChild(tr.tr);
    });

    refresh_repeated_class(by);
  }

  $th_state.click(function() { resort_trs('state'); });
  $th_date.click(function() { resort_trs('date'); });
  refresh_repeated_class('date'); // initial view
});
