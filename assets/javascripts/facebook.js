;(function() {
	document.body.innerHTML += '<div id="fb-root" style="display:none;"></div>';
  (function(d, s, id) {
  var js, fjs = d.getElementsByTagName(s)[0];
  if (d.getElementById(id)) return;
  js = d.createElement(s); js.id = id;
  js.src = "//connect.facebook.net/en_US/all.js#xfbml=1&appId=46744042133";
  fjs.parentNode.insertBefore(js, fjs);
  }(document, 'script', 'facebook-jssdk'));

	var metas = document.getElementsByTagName('meta'); 
	var metaObjs = {};
  for (i=0; i<metas.length; i++) {
  	key = metas[i].getAttribute("property");
  	val = metas[i].getAttribute("content")
  	metaObjs[key] = val;
	}

  fbObj = {
    method: "feed",
    link: document.URL,
    picture: ("og:image" in metaObjs ? metaObjs["og:image"] : ""),
    name: metaObjs["og:title"],
    description: metaObjs["og:description"]
  };

  function postToFacebook() {
    FB.ui(fbObj);
  }

  $(".btn-facebook").click(function(e){
    e.preventDefault();
    postToFacebook();
    return false;
  });
  $(".fa-facebook").click(function(e){
    e.preventDefault();
    postToFacebook();
    return false;
  });
})();
