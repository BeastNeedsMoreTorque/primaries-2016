//= require './vendor/jquery-2.2.0.js'

$(function() {
  // Don't use innerHTML +=, because that breaks ellipsize_table() somehow on all-primaries.html.haml
  $('body').append('<div id="fb-root" style="display:none;"></div>');

  (function(d, s, id) {
  var js, fjs = d.getElementsByTagName(s)[0];
  if (d.getElementById(id)) return;
  js = d.createElement(s); js.id = id;
  js.src = "//connect.facebook.net/en_US/all.js#xfbml=1";
  fjs.parentNode.insertBefore(js, fjs);
  }(document, 'script', 'facebook-jssdk'));

  (function(d, s, id) {
  var js, fjs = d.getElementsByTagName(s)[0];
  if (d.getElementById(id)) return;
  js = d.createElement(s); js.id = id;
  js.src = "//platform.twitter.com/widgets.js";
  fjs.parentNode.insertBefore(js, fjs);
  }(document, 'script', 'twitter-sdk'));

  var meta = {};
  var metas = document.getElementsByTagName('meta'); 
  for (i=0; i < metas.length; i++) {
    var key = metas[i].getAttribute("property") || metas[i].getAttribute("name");
    var val = metas[i].getAttribute("content");
    meta[key] = val;
  }

  var encodedUrl = encodeURIComponent(window.location.href);

  if (meta['fb:app_id']) {
    Array.prototype.forEach.call(document.getElementsByClassName('facebook-share'), function(el) {
      var url = 'https://www.facebook.com/dialog/share?app_id=' + meta['fb:app_id']
        + '&display=popup&href=' + encodedUrl
        + '&redirect_uri=' + encodedUrl;
      el.setAttribute('href', url);
    });
  }

  Array.prototype.forEach.call(document.getElementsByClassName('twitter-share'), function(el) {
    var url = 'https://twitter.com/intent/tweet?text=' + encodeURIComponent(meta['suggested-tweet']) + '&url=' + encodedUrl;
    el.setAttribute('href', url);
  });
});
