$(function() {
  $('body.all-primaries').each(function() {
    wait_for_font_then('Source Sans Pro', function() {
      init_state_race_days();
      init_horse_races();
    });
  });
});
