console.log('Running search-page.js');

var SearchPage = function(url) {
  Page.call(this, 'search');
  this._interfaceListItems = [];

  if (url) {
    this.searchText = url.split('/')[0];
  }
};

SearchPage.prototype = new Page();

Object.defineProperty(SearchPage.prototype, 'searchText', {
  get: function() {
    if (!this._input) {
      return this._initialSearchText;
    } else {
      return this._input.value;
    }
  },
  set: function(newValue) {
    if (!this._input) {
      this._initialSearchText = newValue;
    } else {
      this._input.value = newValue;
      this._onSearchChange(null);
    }
  }
});

Object.defineProperty(SearchPage.prototype, 'interfaces', {
  get: function() {
    return this._interfaces;
  },
  set: function(newInterfaces) {
    this._interfaces = newInterfaces;
    this._siteDescription.style.display = 'none';

    if (!this._interfaces) {
      this._interfaceListItems.forEach(function(item) {
        item.element.style.display = 'none';
      });
      return;
    }

    this._interfaces.forEach(function(anInterface, index) {
      var item = this._interfaceListItems[index];
      if (!item) {
        item = new InterfaceListItem();
        item.showOwnerClass = true;
        item.element.addEventListener(InterfaceListItem.CLICKED_INTERFACE, this._onClickInterface);
        this._interfaceListItems.push(item);
        this._resultList.appendChild(item.element);
      }

      item.interfaceData = anInterface;
      item.element.classList.remove('display-none');
    }, this);

    var itemsToNone = this._interfaceListItems.slice(this._interfaces.length);
    for (var i = 0; i < itemsToNone.length; i++) {
      if (itemsToNone[i].element.classList.contains('display-none')) {
        break;
      }
      item.element.classList.add('display-none');
    }
  }
});

SearchPage.prototype.locationBarUrl = function() {
  if (!this.searchText || this.searchText.length === 0) {
    return '/' + this.pageName;
  }

  return '/' + this.pageName + '/' + this.searchText;
};

SearchPage.prototype.pageTitle = function() {
  if (!this.searchText || this.searchText.length === 0) {
    return 'EasyDocs: Reference for the web platform API';
  }

  return '"' + this.searchText + '": EasyDocs';
};

SearchPage.prototype._didAppear = function() {
  this._input.focus();
};

SearchPage.prototype._didLoad = function() {
  this._input = this.element.querySelector('#search-input');
  this._resultList = this.element.querySelector('.result-list');
  this._header = this.element.querySelector('header');
  this._siteDescription = this.element.querySelector('.site-description');

  this._input.addEventListener('keyup', this._onSearchChange.bind(this));

  if (this._initialSearchText) {
    this.searchText = this._initialSearchText;
    delete this._initialSearchText;
  }
};

SearchPage.prototype._onSearchChange = function(event) {
  var searchString = this._input.value;
  WebDocs.pageStack.updateLocationBarUrl();
  WebDocs.pageStack.updatePageTitle();

  InterfaceDatabase.findInterfaces(searchString, function(foundInterfaces) {
    if (searchString != this._input.value) {
      return;
    }

    this.interfaces = foundInterfaces;
  }.bind(this));
};

SearchPage.prototype._onClickInterface = function(event) {
  var interfaceData = event.detail.interfaceData;
  var classPage = new ClassPage();
  if (interfaceData.interfaceType == 'class') {
    classPage.interfaceData = interfaceData;
  } else {
    classPage.interfaceData = interfaceData.owner;
    classPage.currentMember = interfaceData;
  }

  WebDocs.pageStack.push(classPage, true);
};