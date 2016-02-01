;(function() {
  //load GA
  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');
  //GA helper
  function gaCall(){
    var args = arguments;
    ga(function() {
      var allTrackers = ga.getAll();
      for(var i in allTrackers) {
        new_args = [allTrackers[i].get('name')+'.'+args[0]];
        for(var n = 1; n < args.length; n++){
          new_args.push(args[n]);
        } 
        ga.apply(this, new_args);
        
      }
    });
    
  }
   
  ga('create', 'UA-61898491-1', 'auto', {'name': 'huffpo', 'allowLinker': true});
   
  gaCall('require', 'linker');
  gaCall('require', 'linkid');
  gaCall('require', 'ec');
  gaCall('require', 'displayfeatures');
   
  ga('huffpo.linker:autoLink', ['projects.huffingtonpost.com'], true);
   
  gaCall('send', 'pageview');
}());