window.WebDocs = {
  pageStack: new PageStack(),

  start: function() {
    LoadingScreen.show();

    InterfaceDatabase.loadInterfaces(function() {

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