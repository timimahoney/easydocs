console.log('Running page.js');

var Page = function(pageName) {
  this.pageName = pageName;
  this.element = null;
};

Page.prototype.load = function(callback) {
  if (this.element) {
    callback(this.element);
    return;
  }

  var self = this;
  this._loadHtml(function(loadedElement) {
    self.element = loadedElement;
    self._didLoad();
    callback(self.element);
  });
};

Page.prototype.locationBarUrl = function() {
  return '/' + this.pageName;
};

Page.prototype.pageTitle = function() {
  return 'Webster: Reference for the web platform API';
};

Page.prototype._willAppear = function() {};
Page.prototype._didAppear = function() {};
Page.prototype._willDisappear = function() {};
Page.prototype._didDisappear = function() {};
Page.prototype._didLoad = function() {};

Page.prototype._loadHtml = function(callback) {
  var url = '/html/' + this.pageName + '_page.html';
  this._loadHtmlDefault(url, function(loadedElement) {
    callback(loadedElement);
  });
};

Page.prototype._loadHtmlDefault = function(url, callback) {
  var request = new XMLHttpRequest();
  request.open('GET', url);
  request.responseType = 'document';
  request.onreadystatechange = function() {
    if (request.readyState != XMLHttpRequest.DONE) {
      return;
    }

    var response = request.response;
    if (!response) {
      callback(null);
      return;
    }

    var element = document.createElement('div');
    element.classList.add(this.pageName + '-page');
    var children = [];
    for (var i = 0; i < response.body.childNodes.length; i++) {
      var child = response.body.childNodes.item(i);
      children.push(child);
    }
    children.forEach(function(child) {
      element.appendChild(child);
    });

    callback(element);
  }.bind(this);

  request.send();
};