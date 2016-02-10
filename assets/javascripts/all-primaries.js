$(function() {
  $('body.all-primaries').each(function() {
    // Changing n_trs? Change _race.html.haml as well, or page will scroll while loading
    $('.t-pollster table').ellipsize_table('<button>Show more &#9662;</button>', '<button>Show fewer &#9652;</button>');
  });
});
