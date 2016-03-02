// export these functions
var simple_dot_group_html = null;
var encoded_dot_groups_html = null;

(function() {
  var DotsPerGroup = 25;

  var DotStrings = []; // •, ••, •••, etc
  (function() {
    var i = 0;
    var s = '';

    while (i <= DotsPerGroup) {
      DotStrings.push(s);
      i += 1;
      s += '•';
    }
  })();


  function dot_group(html) {
    return '<div class="dot-group">' + html + '</div>';
  }

  function dot_groups(n_groups, html_in_each) {
    return new Array(n_groups).fill(dot_group(html_in_each)).join('');
  }

  function dot_subgroup(key, value, html) {
    return '<span ' + key + '="' + value + '">' + html + '</span>';
  }

  function dot_string(n_dots) {
    return DotStrings[n_dots];
  }

  /**
   * Builds an HTML String of <div class="dot-group">s.
   *
   * This is a copy of the logic in app/helpers/dot_groups_helper.rb. Change
   * things there, then copy the changes here.
   */
  simple_dot_groups_html = function simple_dot_group_html(n_dots) {
    var htmls = [];

    if (n_dots > DotsPerGroup) {
      htmls.push(dot_groups(Math.floor(n_dots / DotsPerGroup), dot_string(DotsPerGroup)));
    }

    if (n_dots % DotsPerGroup > 0) {
      htmls.push(dot_group(dot_string(n_dots % DotsPerGroup)));
    }

    return htmls.join('');
  };

  /**
   * Builds an HTML String of some <div class="dot-group">s with subgroups,
   * based on the passed input string.
   *
   * @param html_attribute Name of the HTML attribute we set on each subgroup
   * @param encoded_dots String of dot groups separated by `|`, with subgroups
   *                     within separated by ` `. Each subgroup is a
   *                     `value:n-dots` pair.
   */
  encoded_dot_groups_html = function encoded_dot_groups_html(html_attribute, encoded_dot_groups) {
    var dot_group_strings = encoded_dot_groups.split('|').filter(function(s) { return !!s; });

    var html = [];

    dot_group_strings.forEach(function(encoded_dot_subgroups) {
      html.push('<div class="dot-group">');

      encoded_dot_subgroups.split(' ').forEach(function(encoded_dot_subgroup) {
        var arr = encoded_dot_subgroup.split(':');
        var value = arr[0];
        var n_dots = +arr[1];

        html.push('<span ' + html_attribute + '="' + value + '">' + DotStrings[n_dots] + '</span>');
      });

      html.push('</div>');
    });

    return html.join('');
  };
})();
