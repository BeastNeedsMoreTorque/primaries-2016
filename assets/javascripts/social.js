;(function() {
	document.body.innerHTML += '<div id="fb-root" style="display:none;"></div>';

  (function(d, s, id) {
  var js, fjs = d.getElementsByTagName(s)[0];
  if (d.getElementById(id)) return;
  js = d.createElement(s); js.id = id;
  js.src = "//connect.facebook.net/en_US/all.js#xfbml=1&appId=46744042133";
  fjs.parentNode.insertBefore(js, fjs);
  }(document, 'script', 'facebook-jssdk'));

  (function(d, s, id) {
  var js, fjs = d.getElementsByTagName(s)[0];
  if (d.getElementById(id)) return;
  js = d.createElement(s); js.id = id;
  js.src = "//platform.twitter.com/widgets.js";
  fjs.parentNode.insertBefore(js, fjs);
  }(document, 'script', 'twitter-sdk'));

	var metas = document.getElementsByTagName('meta'); 
	var metaObjs = {};
  for (i=0; i<metas.length; i++) {
  	key = metas[i].getAttribute("property");
  	val = metas[i].getAttribute("content")
  	metaObjs[key] = val;
	}

	encodedUrl = encodeURIComponent(window.location.href)
	facebookButtons = document.getElementsByClassName("facebook-share");
	Array.prototype.forEach.call(facebookButtons, function(ele){
		var url = "https://www.facebook.com/dialog/share?app_id=46744042133&display=popup&href="+encodedUrl+"&redirect_uri=" + encodedUrl;
		ele.href = url;
	});
	twitterButtons = document.getElementsByClassName("twitter-share");
  Array.prototype.forEach.call(twitterButtons, function(ele){
    var url = "https://twitter.com/intent/tweet?text="+encodeURIComponent(metaObjs["og:twitter:desc"])+"&url="+encodedUrl;
    ele.href = url;
  });

})();
