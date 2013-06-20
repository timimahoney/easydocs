window.PageStack = function() {
  Page.call(this, 'page-stack');
  this._currentPage = null;
  this._nextPageId = 0;
  this._stack = [];
  this._idToPage = {};
  this._pageToId = {};
  window.addEventListener('popstate', this._onPopState.bind(this));
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
  this._loadAndShowPage(page, animated);
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

PageStack.prototype._loadAndShowPage = function(page, animated) {
  page.load(function() {
    if (page.element) {
      if (this._currentPage) {
        this.hide(this._currentPage, animated);
      }
      this._currentPage = page;
      this.show(this._currentPage, animated);
    }
  }.bind(this));
};

PageStack.prototype.show = function(page, animated, style) {
  if (!page) {
    return;
  }

  animated = defaultIfUndefinedOrNull(animated, true);
  style = defaultIfUndefinedOrNull(style, this.PAGE_BEFORE_SHOW_STYLE);

  page._willAppear();
  page.element.classList.add('page-stack-transition');
  page.element.classList.add('before-show-transparency');
  page.element.classList.add(style);
  this.element.appendChild(page.element);

  window.setTimeout(function() {
    page.element.classList.remove(style);
    page.element.classList.remove('before-show-transparency');

    window.setTimeout(function() {
      page.element.classList.remove('page-stack-transition');
      page._didAppear();
    }.bind(this), 300);
  }.bind(this), 0);
};

PageStack.prototype.hide = function(page, animated, style) {
  if (!page) {
    return;
  }

  animated = defaultIfUndefinedOrNull(animated, true);
  style = defaultIfUndefinedOrNull(style, this.PAGE_AFTER_HIDE_STYLE);

  page._willDisappear();

  if (animated) {
    page.element.classList.add('page-stack-transition');
    page.element.classList.add('after-hide-transparency');
    page.element.classList.add(style);
    window.setTimeout(function() {
      this.element.removeChild(page.element);
      page.element.classList.remove('page-stack-transition');
      page.element.classList.remove('after-hide-transparency');
      page.element.classList.remove(style);
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

  var pageIndex = this._stack.indexOf(pageToShow);
  var previousIndex = this._stack.indexOf(this._currentPage);
  if (previousIndex == -1) {
    previousIndex = 0;
  }
  var goingForward = (pageIndex > previousIndex);
  previousPageNewStyle = goingForward ? this.PAGE_AFTER_HIDE_STYLE : this.PAGE_BEFORE_SHOW_STYLE;
  nextPageNewStyle = goingForward ? this.PAGE_BEFORE_SHOW_STYLE : this.PAGE_AFTER_HIDE_STYLE;

  this.hide(this._currentPage, true, previousPageNewStyle);
  this._currentPage = pageToShow;
  this.show(this._currentPage, true, nextPageNewStyle);

  this.updatePageTitle();
  window.postMessage({ type: 'pageview' }, '*');
};