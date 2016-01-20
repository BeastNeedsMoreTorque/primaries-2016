/**
 * Hides all but the first `n` <tr>s in a <table>'s <tbody>.
 *
 * @param table Table to ellipsize
 * @param n_trs Number of <tr>s we'll display before truncating
 * @param hidden_class Clas name to add to <tr>s we're hiding
 * @param show_html HTML to display as a "show" button
 * @param hide_html HTML to display as a "hide" button
 */
function ellipsize_table(table, n_trs, hidden_class, show_html, hide_html) {
  var $table = $(table);
  var $hidden_trs = $table.find('tbody tr:eq(' + (n_trs - 1) + ')').nextAll();
  var hidden = true;

  if ($hidden_trs.length == 0) return;

  var $container = $table.next();
  if (!$container.is('.ellipsize-table-prompt')) {
    $container = $('<div class="ellipsize-table-prompt"></div>');
    $table.after($container);
  }

  $container.on('click', toggle);

  function toggle(ev) {
    ev.preventDefault();
    if (hidden) show(); else hide();
  }

  function hide() {
    hidden = true;
    $hidden_trs.addClass(hidden_class);
    $container.empty().append(show_html);
  }

  function show() {
    hidden = false;
    $hidden_trs.removeClass(hidden_class);
    $container.empty().append(hide_html);
  }

  hide();
}

$.fn.ellipsize_table = function(n_trs, hidden_class, show_html, hide_html) {
  this.each(function() { ellipsize_table(this, n_trs, hidden_class, show_html, hide_html); });
};
