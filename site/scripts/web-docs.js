console.log('Running web-docs.js');

window.WebDocs = {
  pageStack: new PageStack(),

  start: function() {
    InterfaceDatabase.loadInterfaces(function() {

      WebDocs.pageStack.load(function() {
        document.body.appendChild(WebDocs.pageStack.element);

        var path = window.location.pathname;
        path = path.substr(1);
        var page = URLHandler.pageForUrl(path);
        WebDocs.pageStack.push(page, false);
      });

    });
  }
};