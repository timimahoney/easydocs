console.log('Running page-stack.js');

window.PageStack = function() {
  Page.call(this, 'page-stack');
  this._currentPage = null;
  this._nextPageId = 0;
  this._stack = [];
  this._idToPage = {};
  this._pageToId = {};
  window.addEventListener('popstate', this._onPopState);
};

PageStack.prototype = new Page();

PageStack.prototype.PAGE_AFTER_HIDE_STYLE = 'after-hide-position';
PageStack.prototype.PAGE_BEFORE_SHOW_STYLE = 'before-show-position';

PageStack.prototype.push = function(page, animated) {
  if (!page) {
    return;
  }

  this._stack.push(page);
  this._idToPage[this._nextPageId] = page;
  this._pageToId[page] = this._nextPageId;
  this._nextPageId++;

  if (this._stack.length == 1 && !window.history.state) {
    window.history.replaceState(this._stateObjectForPage(page), null, page.locationBarUrl());
  } else {
    window.history.pushState(this._stateObjectForPage(page), null, page.locationBarUrl());
  }

  this.updatePageTitle();
  window.postMessage({ type: 'pageview' }, '*');
  this.loadAndShowPage(page, animated);
};

PageStack.prototype.updateLocationBarUrl = function() {
  var currentState = window.history.state;
  if (currentState && currentState.pageStack) {
    var page = this._idToPage[currentState.pageId];
    if (!page) {
      return;
    }
    window.history.replaceState(this._stateObjectForPage(page), null, page.locationBarUrl());
  }

  window.postMessage({ type: 'pageview' }, '*');
};

PageStack.prototype.updatePageTitle = function() {
  var currentState = window.history.state;
  if (!currentState || !currentState.pageStack) {
    return;
  }
  var page = this._idToPage[currentState.pageId];
  if (!page) {
    return;
  }

  var title = window.document.head.querySelector('title');
  if (!title) {
    title = window.document.createElement('title');
    window.document.head.appendChild(title);
  }

  title.innerHTML = page.pageTitle();
};

PageStack.prototype._loadHtml = function(callback) {
  var element = window.document.createElement('div');
  element.classList.add('page-stack');
  callback(element);
};

PageStack.prototype._stateObjectForPage = function(page) {
  return {
    pageStack: true,
    pageId: this._pageToId[page],
    pageUrl: page.locationBarUrl()
  };
};

PageStack.prototype.loadAndShowPage = function(page, animated) {
  var self = this;
  page.load(function() {
    if (page.element) {
      if (self._currentPage) {
        self.hide(self._currentPage, animated);
      }
      self._currentPage = page;
      self.show(self._currentPage, animated);
    }
  });
};

PageStack.prototype.show = function(page, animated, style) {
  if (!page) {
    return;
  }

  animated = defaultIfUndefinedOrNull(animated, true);
  style = defaultIfUndefinedOrNull(style, 'page-stack-before-show');

  page._willAppear();
  page.element.classList.add('page-stack-transition', 'before-show-transparency', style);
  this.element.appendChild(page.element);

  window.setTimeout(function() {
    page.element.classList.remove(style, 'before-show-transparency');

    window.setTimeout(function() {
      page.element.classList.remove('page-stack-transition');
      page._didAppear();
    }.bind(this), 300);
  }.bind(this), 0);
};

PageStack.prototype.hide = function(page, style, animated) {
  if (!page) {
    return;
  }

  style = defaultIfUndefinedOrNull(style, this.PAGE_AFTER_HIDE_STYLE);
  animated = defaultIfUndefinedOrNull(animated, true);

  page._willDisappear();

  if (animated) {
    page.element.classList.add('page-stack-transition', 'after-hide-transparency', style);
    window.setTimeout(function() {
      this.element.removeChild(page.element);
      page.element.classList.remove('page-stack-transition', 'after-hide-transparency', style);
      page._didDisappear();
    }.bind(this), 300);
  } else {
    this.element.removeChild(page.element);
    page._didDisappear();
  }
};

PageStack.prototype._onPopState = function(event) {
  if (!event.state || !event.state.pageStack) {
    return;
  }

  var pageToShow = this._idToPage[event.state.pageId];
  if (!pageToShow) {
    return;
  }

  var pageIndex = this._stack.index(pageToShow);
  var previousIndex = this._stack.indexOf(this._currentPage);
  if (previousIndex == -1) {
    previousIndex = 0;
  }
  var goingForward = (pageIndex > previousIndex);
  previousPageNewStyle = goingForward ? this.PAGE_AFTER_HIDE_STYLE : this.PAGE_BEFORE_SHOW_STYLE;
  nextPageNewStyle = goingForward ? this.PAGE_BEFORE_SHOW_STYLE : this.PAGE_AFTER_HIDE_STYLE;

  hide(this._currentPage, previousPageNewStyle);
  this._currentPage = pageToShow;
  show(this._currentPage, nextPageNewStyle);

  updatePageTitle();
  window.postMessage({ type: 'pageview' }, '*');
};