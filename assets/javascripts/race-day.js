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

    console.log(rect, width, height);
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

function position_cities_correctly() {
  $('.party-state-map').each(function() {
    position_svg_cities_correctly(this);
  });
}

$(function() {
  wait_for_font_then('Source Sans Pro', position_cities_correctly)
});

$('.party-state-map').each(function() {
  var $div = $(this);
  var party_id = $div.parent().attr('data-party-id');
  var state_code = $div.parent().attr('data-state-code');
});
