var CandidateColors = {
  Dem: {
    clinton: '#a6c281',
    sanders: '#84c9ec'
  },
  GOP: {
    trump: '#91344c',
    cruz: '#9c788c',
    rubio: '#d98628',
    kasich: '#fa7060',
    carson: '#a85d59'
  }
};

var CandidateColorsNoParties = {};
Object.keys(CandidateColors).forEach(function(key) {
  Object.keys(CandidateColors[key]).forEach(function(slug) {
    CandidateColorsNoParties[slug] = CandidateColors[key][slug];
  });
});
