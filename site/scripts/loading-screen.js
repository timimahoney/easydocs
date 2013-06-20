var LoadingScreen = {
  MINIMUM_SHOW_TIME: 1000,

  show: function() {
    if (!this._element) {
      this._initializeElement();
    }

    this._canHideAt = Date.now() + this.MINIMUM_SHOW_TIME;
    document.body.appendChild(this._element);
    window.setTimeout(function() {
      this._element.classList.remove('hidden');
    }.bind(this), 0);
  },

  hide: function() {
    if (!this._canHideAt || !this._element) {
      return;
    }

    var timeLeftUntilHide = this._canHideAt - Date.now();
    if (timeLeftUntilHide > 0) {
      window.setTimeout(function() {
        this.hide();
      }.bind(this), timeLeftUntilHide);

      return;
    }

    this._element.classList.add('hidden');
    window.setTimeout(function() {
      this._element.parentNode.removeChild(this._element);
    }.bind(this), 400);
  },

  _initializeElement: function() {
    this._element = document.createElement('div');
    this._element.classList.add('loading-screen', 'hidden', 'transition');

    var container = document.createElement('div');
    container.classList.add('loading-container');
    this._element.appendChild(container);

    text = document.createElement('p');
    text.innerHTML = 'Loading data...';
    container.appendChild(text);

    bar = document.createElement('div');
    bar.classList.add('loading-bar');
    container.appendChild(bar);
  }
};