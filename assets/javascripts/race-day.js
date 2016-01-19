function position_cities_correctly() {
  function position_svg_cities_correctly(el) {
    var $el = $(el);
    var $texts = $el.find('text');
    var $svg = $texts.closest('svg');
    var viewBoxStrings = $svg[0].getAttribute('viewBox').split(' ');
    var width = +viewBoxStrings[2];
    var height = +viewBoxStrings[3];

    var rects = []; // Array of { x, y, width, height } Objects

    function rects_intersect(rect1, rect2) {
      return rect1.x < rect2.x + rect2.width && rect1.x + rect1.width > rect2.x && rect1.y < rect2.y + rect2.height && rect1.height + rect1.y > rect2.y;
    }

    function rect_fits(rect) {
      if (rect.x < 0) return false;
      if (rect.y < 0) return false;
      if (rect.x + rect.width > width) return false;
      if (rect.y + rect.height > height) return false;

      return rects.every(function(rect2) { return !rects_intersect(rect, rect2); });
    }

    function trial_rectangles(x, y, width, height) {
      var margin = 5; // px between dot and text
      var x_height = height / 4; // roughly?
      return [
        { position: 'above', x: (x - width / 2), y: y - margin, width: width, height: height },
        { position: 'right', x: x + margin, y: y + x_height, width: width, height: height },
        { position: 'left', x: x - width - margin, y: y + x_height, width: width, height: height },
        { position: 'below', x: (x - width / 2), y: (y + height + margin), width: width, height: height }
      ];
    }

    $texts.each(function() {
      var text = this;
      var x = +text.getAttribute('x');
      var y = +text.getAttribute('y');
      var rect = text.getBBox();
      var potential_rects = trial_rectangles(x, y, rect.width, rect.height);

      for (var i = 0; i < potential_rects.length; i++) {
        var r = potential_rects[i];
        if (rect_fits(r)) {
          rects.push(r);
          text.setAttribute('x', r.x);
          text.setAttribute('y', r.y);
          text.setAttribute('class', r.position);
          return;
        }
      }

      console.warn('Could not position text', text);
    });
  }

  $('.party-state-map').each(function() {
    position_svg_cities_correctly(this);
  });
}

function add_tooltips() {
  // One $tooltip for all <svg>s
  var $tooltip = $('<div class="race-tooltip"><div class="tooltip-contents"><h4></h4><table><thead><tr><th class="candidate">Candidate</th><th class="n-votes">Votes</th></thead><tbody></tbody></table><p class="precincts"><span class="n-reporting">0</span> of <span class="n-total"></span> precincts reporting</p><p class="updated">Last update: <time></time></p></div></div>');
  var svg_hover_path = null;

  function update_tooltip(county_name, candidates, n_reporting, n_total, last_updated) {
    $tooltip.find('h4').text(county_name);
    $tooltip.find('span.n-reporting').text(n_reporting);
    $tooltip.find('span.n-total').text(n_total);
    $tooltip.find('.updated time').text(last_updated.toString());

    $tooltip.find('tbody').empty();

    candidates.forEach(function(candidate) {
      $tr = $('<tr><td class="candidate"></td><td class="n-votes"></td></tr>');
      $tr.find('.candidate').text(candidate.name);
      $tr.find('.n-votes').text(candidate.n_votes);
    });
  }

  function position_tooltip_near_svg_path(svg_path) {
    var margin = 10; // px
    var path_rect = svg_path.getBoundingClientRect();

    var body_width = $('body').width();
    var $div = $(svg_path).closest('div'); // has position: relative

    $div.append($tooltip);
    var div_rect = $div[0].getBoundingClientRect();
    var tooltip_rect = $tooltip[0].getBoundingClientRect();

    var cx = Math.round(path_rect.left - div_rect.left + path_rect.width / 2);
    var y = Math.round(path_rect.top - div_rect.top - tooltip_rect.height - margin);
    var x = cx - $tooltip.width() / 2;

    if (div_rect.left + x < 0) x = -div_rect.left;
    if (div_rect.left + x + tooltip_rect.width > body_width) x = body_width - tooltip_rect.width - div_rect.left;

    $tooltip.css({ left: x + 'px', top: y + 'px' });
  }

  function remove_tooltip() {
    $tooltip.remove();
  }

  function show_tooltip_for_svg_path(svg_path) {
    var county_name = svg_path.getAttribute('data-name');
    var fips_int = +svg_path.getAttribute('data-fips-int');
    var party_id = $(svg_path).closest('[data-party-id]').attr('data-party-id');
    var state_code = $(svg_path).closest('[data-state-code]').attr('data-state-code');

    update_tooltip(county_name, [], 0, 0, new Date());
    position_tooltip_near_svg_path(svg_path);
  }

  function add_hover_path(svg_path) {
    if (svg_hover_path) throw new Error('There is already a hover path');

    var counties = svg_path.parentNode;
    svg_hover_path = svg_path.cloneNode();
    svg_hover_path.setAttribute('class', 'hover');
    counties.appendChild(svg_hover_path);
  }

  function remove_hover_path() {
    svg_hover_path.parentNode.removeChild(svg_hover_path);
    svg_hover_path = null;
  }

  function on_mouseenter() {
    var svg_path = this;
    add_hover_path(svg_path);
    show_tooltip_for_svg_path(svg_path);
  }

  function on_mouseleave() {
    remove_hover_path();
    remove_tooltip();
  }


  function add_tooltip(svg) {
    $(svg)
      .on('mouseenter', 'g.counties path', on_mouseenter)
      .on('mouseleave', 'g.counties path', on_mouseleave);
  }

  $('.party-state-map svg').each(function() {
    add_tooltip(this);
  });
}

$(function() {
  wait_for_font_then('Source Sans Pro', function() {
    position_cities_correctly();
    add_tooltips();
  });
});
