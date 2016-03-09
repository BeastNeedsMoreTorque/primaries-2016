//CMS entry
//http://www.huffingtonpost.com/entry/2016-primaries-dashboard_us_569582cfe4b05b3245daf7f4?gdqp8pvi
//https://us.edit.huffpost.net/cms/entry/569582cfe4b05b3245daf7f4
var isMobile = function(agent){return /(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows (ce|phone)|xda|xiino/i.test(agent)||/1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.test(agent.substr(0,4))}(navigator.userAgent||navigator.vendor||window.opera);
bN_cfg = {
  h: location.hostname,
  p: {
    "dL_ch": (isMobile ? "us.hpmgpol_mb" : "us.hpmgpol"),
    "dL_dpt": "data",
    "cobrand": "HuffPost",
    "dL_blogID": "2",
    "dL_cmsID": "hpo:569582cfe4b05b3245daf7f4",
    "dL_author": "Shane Shifflett",
    "dL_tags": "elections-2016",
    "dL_crtdt": "2016-01-26 10:32:28",
  }
}

function runOmni() {
  s_265.pfxID = 'hpo';
  s_265.channel = (isMobile ? "us.hpmgpol_mb" : "us.hpmgpol");
  s_265.linkInternalFilters = 'javascript:,huffingtonpost.com';
  s_265.prop16 = 'page';
  s_265.prop1 = 'elections';
  s_265.pageName = "" + document.title;
  s_265.prop12 = "" + document.URL.split('?')[0];
  s_265.t();
}

s_265_account ="aolhuffpostpolitics,aolsvc";

(function(d){
var s = d.createElement('script');
s.src = "http://o.aolcdn.com/os_merge/?file=/aol/beacon.min.js&file=/aol/omniture.min.js";
d.getElementsByTagName('head')[0].appendChild(s);
})(document);

document.body.innerHTML += '<div id="parsely-root" style="display:none;"><span id="parsely-cfg" data-parsely-site="huffingtonpost.com"></span></div>';

(function(s, p, d) {
  var h=d.location.protocol, i=p+"-"+s,
      e=d.getElementById(i), r=d.getElementById(p+"-root"),
      u=h==="https:"?"d1z2jf7jlzjs58.cloudfront.net"
      :"static."+p+".com";
  if (e) return;
  e = d.createElement(s); e.id = i; e.async = true;
  e.src = h+"//"+u+"/p.js"; r.appendChild(e);
})("script", "parsely", document);


// Workaround so Omniture tracking code doesn't crash on pages w/ SVG
if (typeof SVGAnimatedString !== 'undefined') {
  SVGAnimatedString.prototype.indexOf = function indexOf() { };
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
var comscoreID = window.setInterval(checkComscore, 1000);

function checkComscore(){
  if(typeof COMSCORE !== 'undefined'){
    runComscore();
    clearInterval(comscoreID)
  }
}
runNielson();
