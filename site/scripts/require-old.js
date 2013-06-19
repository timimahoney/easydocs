function require(urls, callback) {
  Requirer.require(urls, function() {
    callback.call();
  });
}

var Requirer = {
  _urlStatuses: {},
  _unfinishedRequires: [],
  _prefix: '/scripts/',
  _suffix: '.js',

  require: function(urls, callback) {
    var requirerUrl = 'theurlthatisrequiring';

    console.log('requiring ', urls);
    if (!urls || urls.length <= 0 || this._urlsDidFinishOrFail(urls)) {
      _urlStatuses[requirerUrl] = 'finished';
      callback();
      return;
    }

    this._unfinishedRequires.push({
      requirer: requirerUrl,
      callback: callback,
      urls: urls
    });

    var unstartedUrls = [];
    urls.forEach(function(url) {
      if (!this._urlStatuses[url]) {
        unstartedUrls.push(url);
      }
    }, this);

    unstartedUrls.forEach(function(url) {
      this._urlStatuses[url] = 'loading';
      var scriptElement = document.createElement('script');
      scriptElement.type = 'text/javascript';
      scriptElement.src = this._prefix + url + this._suffix;
      console.log('script url', scriptElement.src);
      scriptElement.async = false;
      scriptElement.onload = function() {
        console.log('loaded ', url);
        this._urlStatuses[url] = 'loaded';
        this._callCallbacksForFinishedRequires();
      }.bind(this);
      scriptElement.onerror = function() {
        this._urlStatuses[url] = 'error';
        this._callCallbacksForFinishedRequires();
      }.bind(this);
      document.head.appendChild(scriptElement);
    }, this);
  },

  _callCallbacksForFinishedRequires: function() {
    var finishedRequires = this._unfinishedRequires.filter(function(requireList) {
      return this._urlsDidFinishOrFail(requireList.urls);
    }, this);

    this._unfinishedRequires = this._unfinishedRequires.filter(function(requireList) {
      return !this._urlsDidFinishOrFail(requireList.urls);
    }, this);

    finishedRequires.forEach(function(requireList) {
      if (requireList.callback) {
        console.log('running from require for: ', requireList.urls);
        requireList.callback();
      }
    });
  },

  _urlsDidFinishOrFail: function(urls) {
    return urls.every(function(url) {
      var status = this._urlStatuses[url];
      return status == 'finished' || status == 'error';
    }, this);
  }
};