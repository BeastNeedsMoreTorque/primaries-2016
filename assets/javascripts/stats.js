;(function() {
  //CMS entry
  //http://www.huffingtonpost.com/entry/2016-primaries-dashboard_us_569582cfe4b05b3245daf7f4?gdqp8pvi
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
    if(typeof s_265 !== 'undefined'){
      runOmni();
      clearInterval(omniID)
    }
  }
  function checkComscore(){
    if(typeof COMSCORE !== 'undefined'){
      runComscore();
      clearInterval(comscoreID)
    }
  }
  runNielson();
}());