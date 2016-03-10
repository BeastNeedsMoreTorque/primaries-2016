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

  Array.prototype.forEach.call(document.querySelectorAll('div.race:not(.not-today)'), function(raceEl) {
    var party_id = raceEl.getAttribute('data-party-id');
    var state_code = raceEl.getAttribute('data-state-code');

    if (!races.hasOwnProperty(party_id)) { races[party_id] = {}; }
    var psd = raceEl.querySelector('.party-state-delegates');
    races[party_id][state_code] = {
      div: raceEl,
      n_precincts: raceEl.querySelectorAll('.race-status .n-precincts-reporting'),
      last_updated: raceEl.querySelector('.race-status time'),
      n_delegates_with_candidates: {
        dots: psd.querySelector('.n-delegates-dots'),
        int_with_candidates: psd.querySelector('.n-delegates-with-candidates-int'),
        int_total: psd.querySelector('.n-delegates-int')
      },
      n_pledged_delegates_with_candidates: {
        dots: psd.querySelector('.n-pledged-delegates-dots'),
        int_with_candidates: psd.querySelector('.n-pledged-delegates-with-candidates-int'),
        int_total: psd.querySelector('.n-pledged-delegates-int')
      }
    };

    Array.prototype.forEach.call(raceEl.querySelectorAll('table.candidates tbody tr'), function(tr, i) {
      var candidate_id = tr.getAttribute('data-candidate-id');

      if (!candidate_races.hasOwnProperty(candidate_id)) { candidate_races[candidate_id] = {}; }
      o = candidate_races[candidate_id];

      o[state_code] = {
        tr: tr,
        n_votes: tr.querySelector('.n-votes'),
        percent_vote: tr.querySelector('.percent-vote'),
        n_delegates_dots: tr.querySelector('td.n-delegates-dots'),
        n_delegates_int: tr.querySelector('td.n-delegates'),
        n_pledged_delegates_dots: tr.querySelector('td.n-pledged-delegates-dots'),
        n_pledged_delegates_int: tr.querySelector('td.n-pledged-delegates')
      };
    });

    if (!county_races.hasOwnProperty(party_id)) county_races[party_id] = {};
    o = county_races[party_id];
    Array.prototype.forEach.call(raceEl.querySelectorAll('g.counties path'), function(path) {
      var fips_int = path.getAttribute('data-fips-int');
      o[fips_int] = {
        path: path
      };
    });

    if (!race_subcounties.hasOwnProperty(party_id)) race_subcounties[party_id] = {};
    o = race_subcounties[party_id];
    Array.prototype.forEach.call(raceEl.querySelectorAll('g.subcounties path'), function(path) {
      var geo_id = path.getAttribute('data-geo-id');
      o[geo_id] = {
        path: path
      };
    });
  });
}
