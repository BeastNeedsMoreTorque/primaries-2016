// All the page's important HTML Nodes, indexed by unique ID
function RaceDayNodes() {
  var o;

  // candidate_id -> state_code -> { tr, n_votes, percent_vote, n_delegates_dots, n_delegates_int, n_pledged_delegates_dots, n_pledged_delegates_int }
  var candidate_races = this.candidate_races = {};

  // party_id -> { fips_int -> { path } }
  var county_races = this.county_races = {};

  // party_id -> { geo_id -> { path } }
  var race_subcounties = this.race_subcounties = {};

  // party_id -> state_code -> { div, n_precincts, last_updated, n_delegates_with_candidates, n_pledged_delegates_with_candidates }
  var races = this.races = {};

  $('div.race:not(.not-today)').each(function() {
    var party_id = this.getAttribute('data-party-id');
    var state_code = this.getAttribute('data-state-code');

    if (!races.hasOwnProperty(party_id)) { races[party_id] = {}; }
    var $psd = $('.party-state-delegates', this);
    races[party_id][state_code] = {
      div: this,
      n_precincts: $('.race-status .n-precincts-reporting', this),
      last_updated: $('.race-status time', this),
      n_delegates_with_candidates: {
        dots: $psd.find('.n-delegates-dots'),
        int_with_candidates: $psd.find('.n-delegates-with-candidates-int'),
        int_total: $psd.find('.n-delegates-int')
      },
      n_pledged_delegates_with_candidates: {
        dots: $psd.find('.n-pledged-delegates-dots'),
        int_with_candidates: $psd.find('.n-pledged-delegates-with-candidates-int'),
        int_total: $psd.find('.n-pledged-delegates-int')
      }
    };

    $('table.candidates tbody tr').each(function(i) {
      var candidate_id = this.getAttribute('data-candidate-id');

      if (!candidate_races.hasOwnProperty(candidate_id)) { candidate_races[candidate_id] = {}; }
      o = candidate_races[candidate_id];

      o[state_code] = {
        tr: this,
        n_votes: $('.n-votes', this),
        percent_vote: $('.percent-vote', this),
        n_delegates_dots: $('td.n-delegates-dots', this),
        n_delegates_int: $('td.n-delegates', this),
        n_pledged_delegates_dots: $('td.n-pledged-delegates-dots', this),
        n_pledged_delegates_int: $('td.n-pledged-delegates', this)
      };
    });

    o = county_races[party_id] = {};
    $('g.counties path', this).each(function() {
      var fips_int = this.getAttribute('data-fips-int');
      o[fips_int] = {
        path: this
      };
    });

    o = race_subcounties[party_id] = {};
    $('g.subcounties path', this).each(function() {
      var geo_id = this.getAttribute('data-geo-id');
      o[geo_id] = {
        path: this
      };
    });
  });
}
