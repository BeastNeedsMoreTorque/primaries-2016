function Candidate(line) {
  var arr = line.split(',');

  this.id = arr[0];
  this.party_id = arr[1];
  this.last_name = arr[2];
  this.n_delegates = +arr[3];
  this.n_pledged_delegates = +arr[4];
}

function CandidateCountyRace(line) {
  var arr = line.split(',');

  this.candidate_id = arr[0];
  this.geo_id = +arr[1];
  this.n_votes = +arr[2];
}

function CandidateRace(line) {
  var arr = line.split(',');

  this.candidate_id = arr[0];
  this.state_code = arr[1];
  this.n_votes = +arr[2];
  this.percent_vote = +arr[3];
  this.n_delegates = +arr[4];
  this.n_pledged_delegates = +arr[5];
  this.winner = arr[6] == 'true';
}

function CandidateRaceSubcounty(line) {
  var arr = line.split(',');

  this.candidate_id = arr[0];
  this.geo_id = +arr[1];
  this.n_votes = +arr[2];
}

function CountyRace(line) {
  var arr = line.split(',');

  this.geo_id = +arr[0];
  this.party_id = arr[1];
  this.n_votes = +arr[2];
  this.n_precincts_reporting = +arr[3];
  this.n_precincts_total = +arr[4];
}

function Race(line) {
  var arr = line.split(',');

  this.party_id = arr[0];
  this.state_code = arr[1];
  this.n_precincts_reporting = +arr[2];
  this.n_precincts_total = +arr[3];
  this.has_delegate_counts = arr[4] == 'true';
  this.has_pledged_delegate_counts = arr[5] == 'true';
  this.last_updated = new Date(arr[6]);
  this.when_race_happens = arr[7]; // 'past', 'present' or 'future'
  this.n_delegates_with_candidates = +arr[8];
  this.n_delegates = +arr[9];
  this.n_pledged_delegates_with_candidates = +arr[10];
  this.n_pledged_delegates = +arr[11];
  this.party_state_id = this.party_id + '-' + this.state_code;
}

function RaceSubcounty(line) {
  var arr = line.split(',');

  this.party_id = arr[0];
  this.geo_id = +arr[1];
  this.n_votes = +arr[2];
  this.n_precincts_reporting = +arr[3];
  this.n_precincts_total = +arr[4];
}

var RaceDayTables = [
  { id: 'candidates', name: 'candidate', klass: 'Candidate' },
  { id: 'candidate_county_races', name: 'candidate_county_race', klass: 'CandidateCountyRace' },
  { id: 'candidate_races', name: 'candidate_race', klass: 'CandidateRace' },
  { id: 'candidate_race_subcounties', name: 'candidate_race_subcounty', klass: 'CandidateRaceSubcounty' },
  { id: 'county_races', name: 'county_race', klass: 'CountyRace' },
  { id: 'races', name: 'race', klass: 'Race' },
  { id: 'race_subcounties', name: 'race_subcounty', klass: 'RaceSubcounty' }
];

function RaceDay(race_day_json) {
  var o, o2, candidates_by_id;

  for (var i = 0; i < RaceDayTables.length; i++) {
    o = RaceDayTables[i];

    var csv = race_day_json[o.name + '_csv'];
    var lines = csv.split('\n').slice(1);
    var rows = lines.map(function(line) { return new window[o.klass](line) });

    this[o.id] = rows;
  }

  o = this.candidates_by_id = candidates_by_id = {};
  this.candidates.forEach(function(candidate) {
    o[candidate.id] = candidate;
  });

  o = this.races_by_ids = { Dem: {}, GOP: {}};
  this.races.forEach(function(race) {
    o[race.party_id][race.state_code] = race;
  });

  o = this.geo_races_by_ids = { Dem: {}, GOP: {} };
  this.county_races.forEach(function(county_race) {
    o[county_race.party_id][county_race.geo_id] = county_race;
  });
  this.race_subcounties.forEach(function(race_subcounty) {
    o[race_subcounty.party_id][race_subcounty.geo_id] = race_subcounty;
  });

  o = this.candidate_geo_races_by_geo_ids = { Dem: {}, GOP: {} };
  this.candidate_county_races.forEach(function(ccr) {
    var party_id = candidates_by_id[ccr.candidate_id].party_id;
    o2 = o[party_id];
    if (!o2.hasOwnProperty(ccr.geo_id)) { o2[ccr.geo_id] = []; }
    o2[ccr.geo_id].push(ccr);
  });
  this.candidate_race_subcounties.forEach(function(crs) {
    var party_id = candidates_by_id[ccr.candidate_id].party_id;
    o2 = o[party_id];
    if (!o2.hasOwnProperty(crs.geo_id)) { o2[crs.geo_id] = []; }
    o2[crs.geo_id].push(crs);
  });
}
