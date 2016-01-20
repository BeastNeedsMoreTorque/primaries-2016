$(function() {
  $('body.all-primaries').each(function() {
    // Changing n_trs? Change _race.html.haml as well, or page will scroll while loading
    $('.t-pollster table').ellipsize_table(5, 'ellipsized', '<button>Show more…</button>', '<button>Show fewer…</button>');
  });
});
