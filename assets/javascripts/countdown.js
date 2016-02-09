var _countdown_time = 30;
var _countdown_timer_id = null;
var _start_countdown = function(){
	if(_countdown_timer_id !== null){
		clearInterval(_countdown_timer_id);
		_countdown_timer_id = null;
		_countdown_time = 30;
	}
	var _countdown_timer_id = setInterval(function(){
		if(_countdown_time-- <= 0){
			_countdown_time = 30;
			clearInterval(_countdown_timer_id);
			_countdown_timer_id = null;
		}
		var display = "0:" + (_countdown_time < 10 ? "0" + _countdown_time : _countdown_time)
		$(".refresh-flag span").text(display);
	}, 1000);
};