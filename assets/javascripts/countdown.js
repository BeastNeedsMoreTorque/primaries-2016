var Countdown = function(){
	this._countdown_time = 30;
	this._countdown_timer_id = null;
	var self = this;
};
Countdown.prototype.count = function(){
	if(self._countdown_timer_id !== null){
		clearInterval(self._countdown_timer_id);
		self._countdown_timer_id = null;
		self._countdown_time = 30;
	}
	self._countdown_timer_id = setInterval(function(){
		if(--self._countdown_time <= 0){
			self._countdown_time = 30;
			clearInterval(self._countdown_timer_id);
			self._countdown_timer_id = null;
		}
		self.display = "0:" + (self._countdown_time < 10 ? "0" + self._countdown_time : self._countdown_time)
		$(".refresh-flag span").text(self.display);
	}, 1000);
};