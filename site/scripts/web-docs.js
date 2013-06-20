window.WebDocs = {
  pageStack: new PageStack(),

  start: function() {

    // Wait a bit before showing the loading screen.
    // That way, it won't show for very short loads.
    var loadingTimeoutId = window.setTimeout(function () {
      LoadingScreen.show();
    }, 100);

    InterfaceDatabase.loadInterfaces(function() {
      window.clearTimeout(loadingTimeoutId);

      WebDocs.pageStack.load(function() {
        document.body.insertBefore(WebDocs.pageStack.element, document.body.firstElementChild);

        var path = window.location.pathname;
        path = path.substr(1);
        var page = URLHandler.pageForUrl(path);
        WebDocs.pageStack.push(page, false);

        LoadingScreen.hide();
      });

    });
  }
};