$(function() {
  $('body.all-primaries').each(function() {
    // Changing n_trs? Change _race.html.haml as well, or page will scroll while loading
    $('.t-pollster table').ellipsize_table('<button>Show more &#9662;</button>', '<button>Show fewer &#9652;</button>');

    $(document).on('click', 'input[name=include-unpledged-delegates]', function(ev) {
      var checked = this.checked;
      $('input[name=include-unpledged-delegates]').prop('checked', checked);
      $('.pollster-tables')
        .toggleClass('show-n-delegates', checked)
        .toggleClass('show-n-pledged-delegates', !checked)
        ;
    });

    wait_for_font_then('Source Sans Pro', init_state_race_days);
  });
});
