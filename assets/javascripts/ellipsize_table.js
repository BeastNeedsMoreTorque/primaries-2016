/**
 * Toggles a <table>'s "ellipsized" class, with buttons it adds after the
 * <table>.
 *
 * Does nothing if there is no <tr class="ellipsized"> within the table.
 *
 * @param table Table to ellipsize
 * @param show_html HTML to display as a "show" button
 * @param hide_html HTML to display as a "hide" button
 */
function ellipsize_table(table, show_html, hide_html) {
  var $table = $(table);

  if ($table.find('tr.ellipsized').length == 0) return;

  var ellipsized = $table.hasClass('ellipsized');
  var $container = $table.next();

  if (!$container.is('.ellipsize-table-prompt')) {
    $container = $('<div class="ellipsize-table-prompt"></div>');
    $table.after($container);
  }

  $container.on('click', toggle);

  function toggle(ev) {
    ev.preventDefault();
    if (ellipsized) show(); else hide();
  }

  function hide() {
    ellipsized = true;
    $table.addClass('ellipsized');
    $container.html(show_html);
  }

  function show() {
    ellipsized = false;
    $table.removeClass('ellipsized');
    $container.html(hide_html);
  }

  hide();
}

$.fn.ellipsize_table = function(show_html, hide_html) {
  this.each(function() { ellipsize_table(this, show_html, hide_html); });
};
