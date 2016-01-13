;(function() {
  //load GA
  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');
  //load omniture/comscore
  (function(d){
    var s = d.createElement('script');
    s.src = "http://o.aolcdn.com/os_merge/?file=/aol/beacon.min.js&file=/aol/omniture.min.js";
    d.getElementsByTagName('head')[0].appendChild(s);
    document.write(unescape("%3Cscript src='" + (document.location.protocol == "https:" ? "https://sb" : "http://b") + ".scorecardresearch.com/beacon.js' %3E%3C/script%3E"));
  })(document);
   
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

  //CMS entry
  //https://us.edit.huffpost.net/cms/entry/569582cfe4b05b3245daf7f4
  bN_cfg = {
    h: location.hostname,
    p: {
      "dL_ch": "us.hpmgpol",
      "dL_dpt": "data",
      "cobrand": "HuffPost",
      "dL_blogID": "2",
      "dL_cmsID": "hpo:569582cfe4b05b3245daf7f4",
    }
  }

  function runOmni() {
    // Workaround so Omniture tracking code doesn't crash on pages w/ SVG
    if (typeof SVGAnimatedString !== 'undefined') {
      SVGAnimatedString.prototype.indexOf = function indexOf() { };
    }
    s_265.pfxID = 'hpo';
    s_265.channel = 'us.hpmgpol';
    s_265.linkInternalFilters = 'javascript:,huffingtonpost.com';
    s_265.prop16 = 'page';
    s_265.prop1 = 'data';
    s_265.pageName = "" + document.title;
    s_265.prop12 = "" + document.URL.split('?')[0];
    s_265_account ="aolhuffpostpol,aolsvc";
    s_265.t();
  }

  function runComscore() {
    COMSCORE.beacon({
        c1:2,
        c2:6723616,
        c3:"",
        c4:"",
        c5:"politics",
        c6:"",
        c15:"",
              options: {
                  url_append: "comscorekw=politics"
              }
    }); 
  }

  function runNielson(){
    document.body.innerHTML += '<div id="nielson-tracker" style="display:none;"></div>';
    var d = new Image(1, 1);
    d.onerror = d.onload = function() {
        d.onerror = d.onload = null;
    };
    var ts_value = "ts=compact";

    d.src = [
        "//secure-us.imrworldwide.com/cgi-bin/m?ci=us-703240h&cg=0&cc=1&si=",
        escape(window.location.href),
        "&rp=",
        escape(document.referrer),
        "&",
        ts_value,
        "&rnd=",
        (new Date()).getTime()
    ].join('');

    document.getElementById('nielson-tracker').appendChild(d);
  }
  var omniID = window.setInterval(checkOmni, 1000);
  var comscoreID = window.setInterval(checkComscore, 1000);

  function checkOmni(){
    if(s_265 !== undefined){
      runOmni();
      clearInterval(omniID)
    }
  }
  function checkComscore(){
    if(s_265 !== undefined){
      runComscore();
      clearInterval(comscoreID)
    }
  }
  runNielson();
}());