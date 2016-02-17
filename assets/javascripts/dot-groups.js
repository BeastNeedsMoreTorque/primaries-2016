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

  function dot_subgroup(class_name, html) {
    return '<div class="dot-subgroup ' + class_name + '">' + html + '</div>';
  }

  function dot_string(n_dots) {
    return DotStrings[n_dots];
  }

  /**
   * Sets the inner HTML to be some <div class="dot-group">s.
   *
   * This is a copy of the logic in app/helpers/dot_groups_helper.rb. Change
   * things there, then copy the changes here.
   */
  $.fn.assign_simple_dot_groups = function(n_dots) {
    var htmls = [];

    if (n_dots > DotsPerGroup) {
      htmls.push(dot_groups(Math.floor(n_dots / DotsPerGroup), dot_string(DotsPerGroup)));
    }

    if (n_dots % DotsPerGroup > 0) {
      htmls.push(dot_group(dot_string(n_dots % DotsPerGroup)));
    }

    this.html(htmls.join(''));
  };

  /**
   * Sets the inner HTML to be some <div class="dot-group">s with two inner
   * <div class="dot-subgroup"> classes.
   */
  $.fn.assign_bisected_dot_groups = function(class1, n_dots1, class2, n_dots2) {
    var htmls = [];

    // Handle full class-1 dot-groups
    if (n_dots1 >= DotsPerGroup) {
      htmls.push(dot_groups(Math.floor(n_dots1 / DotsPerGroup), dot_subgroup(class1, dot_string(DotsPerGroup))));
    }

    // Handle partial class-1 and class-2 dot-groups
    var remainder = n_dots1 % DotsPerGroup;
    var partial_dots2 = n_dots2;
    if (remainder > 0) {
      var parts = [ dot_subgroup(class1, dot_string(remainder)) ];

      if (n_dots2 >= DotsPerGroup - remainder) {
        partial_dots2 -= (DotsPerGroup - remainder);
        parts.push(dot_subgroup(class2, dot_string(DotsPerGroup - remainder)));
      } else if (n_dots2 > 0) {
        partial_dots2 = 0;
        parts.push(dot_subgroup(class2, dot_string(n_dots2)));
      }

      htmls.push(dot_group(parts.join('')));
    }

    // Handle full and partial class-2 dot-groups
    if (partial_dots2 >= DotsPerGroup) {
      htmls.push(dot_groups(Math.floor(partial_dots2 / DotsPerGroup), dot_subgroup(class2, dot_string(DotsPerGroup))));
    }

    if ((partial_dots2 % DotsPerGroup) > 0) {
      htmls.push(dot_group(dot_subgroup(class2, dot_string(partial_dots2 % DotsPerGroup))));
    }

    this.html(htmls.join(''));
  }
})();
