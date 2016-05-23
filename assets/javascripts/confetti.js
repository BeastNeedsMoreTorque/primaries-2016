window.Confetti = (function() {
  var R = 5; // Distance from center of confetti paper to corner

  function Paper(x0, y0, phi0, theta, color, t0, v) {
    this.x0 = x0;
    this.y0 = y0;
    this.phi0 = phi0;
    this.theta = theta;
    this.color = color;
    this.t0 = t0;
    this.v = v;

    // Each paper never rotates. It just flips about the Y axis.
    // Calculate the Xs and maximum Yx.
    var cosT = Math.cos(theta);
    var sinT = Math.sin(theta);
    this.dxs = [
      R * cosT,  //Math.cos(theta),
      R * sinT,  //Math.cos(theta + Math.PI / 2),
      R * -cosT, //Math.cos(theta + Math.PI),
      R * -sinT  //Math.cos(theta + Math.PI * 3 / 2)
    ];
    this.dys = [
      R * sinT,  //Math.sin(theta),
      R * -cosT, //Math.sin(theta + Math.PI / 2),
      R * -sinT, //Math.sin(theta + Math.PI),
      R * cosT   //Math.sin(theta + Math.PI * 3 / 2)
    ];

    this.update(t0);
  }

  Paper.prototype.update = function(t) {
    var dt = t - this.t0;
    var d = this.v * dt;

    this.x = this.x0 + Math.cos(this.theta + t / 1000) * this.v * 200;
    this.y = this.y0 + d;
    this.phi = this.phi0 + d / 20;
  };

  Paper.prototype.draw = function(ctx) {
    var scale = Math.sin(this.phi);

    ctx.fillStyle = scale > 0 ? this.color : '#ffffff';
    ctx.beginPath();
    ctx.moveTo(this.x + this.dxs[0], this.y + this.dys[0] * scale);
    for (var i = 1; i < 4; i++) {
      ctx.lineTo(this.x + this.dxs[i], this.y + this.dys[i] * scale);
    }
    ctx.closePath();
    ctx.fill();
  };

  function Confetti(container, color) {
    this.color = color;

    this.container = container;
    this.canvas = document.createElement('canvas');
    this.canvas.className = 'confetti';
    container.appendChild(this.canvas);

    // HACK: The dimensions are specific to horse-race....
    this.set_size_from_horse_race();

    this.ctx = this.canvas.getContext('2d');

    var _this = this;
    this.on_resize = function() { _this.set_size_from_horse_race(); };
    window.addEventListener('resize', this.on_resize);

    this.n_papers = 80;
    this.papers = [];
  }

  Confetti.prototype.remove = function() {
    this.stop();
    this.container.removeChild(this.canvas);
    window.removeEventListener(this.on_resize);
  };

  Confetti.prototype.set_size_from_horse_race = function() {
    var div = this.container;
    var needed = div.querySelector('div.n-delegates-needed');
    var ol = div.querySelector('ol.candidate-horses');

    var width = Math.floor(ol.clientWidth);
    var height = Math.floor(ol.clientHeight);

    this.width = this.canvas.width = width;
    this.height = this.canvas.height = height;
    this.canvas.style.position = 'absolute';
    this.canvas.style.pointerEvents = 'none';
    this.canvas.style.top = needed.clientHeight + 'px';
  };

  Confetti.prototype._addPaper = function(t) {
    // Random is slow
    var rand1 = Math.random();
    var rand2 = Math.random();
    var rand3 = Math.random();

    this.papers.push(new Paper(
      this.width * rand1,
      10 * rand2,
      2 * Math.PI * rand2,
      2 * Math.PI * rand3,
      this.color,
      t,
      0.1 * rand2 + 0.15
    ));
  };

  Confetti.prototype.render_frame = function(t) {
    // Update existing papers
    this.papers.forEach(function(p) { p.update(t) });

    // Nix papers that are off the screen
    var h = this.height;
    var w = this.width;
    this.papers = this.papers.filter(function(paper) {
      return paper.y < (h + R) && paper.x > -R && paper.x < (w + R);
    });

    // Add more papers: at most 2 per frame -- the math is slow
    var n_to_add = Math.min(2, Math.max(0, this.n_papers - this.papers.length));
    for (var i = 0; i < n_to_add; i++) {
      this._addPaper(t);
    }

    this.ctx.clearRect(0, 0, this.width, this.height);
    for (var j = 0; j < this.papers.length; j++) {
      this.papers[j].draw(this.ctx);
    }
  };

  Confetti.prototype.start = function() {
    var _this = this;

    var render = function(t) {
      _this.render_frame(t);
      _this.next_frame = window.requestAnimationFrame(render);
    }

    _this.next_frame = window.requestAnimationFrame(render);
  };

  Confetti.prototype.stop = function() {
    if (this.next_frame !== null) {
      window.cancelAnimationFrame(this.next_frame);
      this.next_frame = null;
      this.ctx.clearRect(0, 0, this.width, this.height);
    }
  };

  return Confetti;
})();
