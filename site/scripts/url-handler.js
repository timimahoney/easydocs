var URLHandler = {

  pageForUrl: function(url) {
    var splitPath = url.split('/');
    var topLevelPath = splitPath.shift();
    var remainingUrl = splitPath.join('/');

    switch (topLevelPath) {
      case 'search':
        return new SearchPage(remainingUrl);

      case 'class':
        if (ClassPage.isValidUrl(remainingUrl)) {
          return new ClassPage(remainingUrl);
        }
        return new SearchPage(remainingUrl);

      default:
        return new SearchPage();
    }
  }

};