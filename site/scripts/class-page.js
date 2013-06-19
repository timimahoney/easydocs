var ClassPage = function(url) {
  Page.call(this, 'class');

  if (url) {
    urlParts = url.split('/');
    var className = urlParts[0];
    var memberName = urlParts[1];
    if (className) {
      this.interfaceData = InterfaceDatabase.findInterface(className, 'class');
      this.currentMember = this._findMember(memberName);
    }
  }
};

ClassPage.prototype = new Page();

ClassPage.prototype.PLACEMARKER_UPDATE_INTERVAL = 0.1;

Object.defineProperty(ClassPage.prototype, 'interfaceData', {
  get: function() {
    return this._interfaceData;
  },
  set: function(newData) {
    this._interfaceData = newData;

    if (this._interfaceData) {
      this._methods = this._interfaceData.methods;
      this._attributes = this._interfaceData.attributes;
      var parent = this._interfaceData.parent;
      while (parent) {
        this._methods = this._methods.concat(parent.methods);
        this._attributes = this._attributes.concat(parent.attributes);
        parent = parent.parent;
      }
      var stringSort = function(a, b) {
        return a.name.localeCompare(b.name);
      };
      this._methods.sort(stringSort);
      this._attributes.sort(stringSort);
    }

    if (this.element) {
      this._updateInterfaceElements();
    }
  }
});


Object.defineProperty(ClassPage.prototype, 'currentMember', {
  get: function() {
    return this._currentMember;
  },
  set: function(newMember) {
    this._currentMember = newMember;
    WebDocs.pageStack.updateLocationBarUrl();
    this._updateCurrentMemberDimming();
  }
});

ClassPage.isValidUrl = function(url) {
  if (!url) {
    return false;
  }

  var className = url.split('/')[0];
  var interfaceData = InterfaceDatabase.findInterface(className, 'class');
  if (!interfaceData) {
    return false;
  }

  return true;
};

ClassPage.prototype.locationBarUrl = function() {
  var url = '/' + this.pageName;
  if (this._interfaceData) {
    url += '/' + this._interfaceData.name;
  }
  if (this._currentMember) {
    url += '/' + this._currentMember.name;
  }
  return url;
}

ClassPage.prototype.pageTitle = function() {
  if (!this._interfaceData) {
    return null;
  }

  return this._interfaceData.name + ': EasyDocs';
};

ClassPage.prototype._willAppear = function() {
  this._updateCurrentMemberDimming();
};

ClassPage.prototype._didAppear = function() {
  this._updatePlacemarker();
};

ClassPage.prototype._didLoad = function() {
  this._contentContainer = this.element.querySelector('.content');
  this._methodsList = this.element.querySelector('.member-list.methods');
  this._attributesList = this.element.querySelector('.member-list.attributes');
  this._attributesSidebarList = this.element.querySelector('.sidebar-list.attributes');
  this._methodsSidebarList = this.element.querySelector('.sidebar-list.methods');
  this._titleElement = this.element.querySelector('header>h1');
  this._interfaceDescriptionElement = this.element.querySelector('.interface-description');
  this._interfaceListItem = new InterfaceListItem();
  this._interfaceListItem.isHeaderClickable = false;
  this._interfaceDescriptionElement.appendChild(this._interfaceListItem.element);
  this._placemarker = this.element.querySelector('.place-marker');
  this._sidebarListContainer = this.element.querySelector('.sidebar-list-container');

  this._contentContainer.onscroll = this._onScrollContent;
  this.element.querySelector('.search-button').onclick = this._onClickSearch;

  this._updateInterfaceElements();
  this._scrollToMember(this.currentMember);
};

ClassPage.prototype._updateCurrentMemberDimming = function() {
  if (!this._attributesList || !this._methodsList) {
    return;
  }

  var attributeItems = Array.prototype.slice.call(this._attributesList.childNodes);
  var methodItems = Array.prototype.slice.call(this._methodsList.childNodes);
  var allListItems = attributeItems.concat(methodItems);
  if (!this.currentMember) {
    this._undimAll();
  } else {
    this._dimAllExceptCurrentMember();
  }
};

ClassPage.prototype._undimAll = function() {
  allListItems.forEach(function(item) {
    item.classList.remove('dim');
  });
  window.setTimeout(function() {
    allListItems.forEach(function(item) {
      item.classList.remove('transition');
    });
  }, 1);
};

ClassPage.prototype._dimAllExceptCurrentMember = function() {
  var allMembers = this._attributes.concat(this._methods);
  var memberIndex = allMembers.index(this._currentMember);
  allListItems.forEach(function(item, index) {
    if (index == memberIndex) {
      item.classList.remove('dim', 'transition');
    } else {
      item.classList.add('dim', 'transition');
    }
  });
};

ClassPage.prototype._onClickSearch = function(event) {
  var searchPage = new SearchPage();
  WebDocs.pageStack.push(searchPage, true);
};

ClassPage.prototype._onScrollContent = function(event) {
  if (!this._scrollingProgrammatically && this._currentMember) {
    this.currentMember = null;
  }
  this._scrollingProgrammatically = false;

  this._updatePlacemarker();
};

ClassPage.prototype._updatePlacemarker = function() {
  // // Don't update the placemarker position too often. Otherwise, it's slow.
  // now = Time.now.to_f
  // time_since_last_update = now - (@last_placemarker_update || 0)
  // return if time_since_last_update < PLACEMARKER_UPDATE_INTERVAL
  // @last_placemarker_update = now.to_f

  // Find the top and bottom visible elements, then move the marker to cover those.
  var minimumTop = this._contentContainer.scrollTop;
  var maximumBottom = this._contentContainer.scrollTop + this._contentContainer.offsetHeight;
  var allChildren = nodeListToArray(this._attributesList.childNodes).concat(nodeListToArray(this._methodsList.childNodes));
  var visibleChildren = allChildren.filter(function(child) {
    return (child.offsetTop + child.offsetHeight > minimumTop) && (child.offsetTop < maximumBottom);
  });

  var firstVisibleIndex = allChildren.indexOf(visibleChildren[0]);
  var lastVisibleIndex = allChildren.index(visibleChildren[visibleChildren.length - 1]);

  var allSidebarChildren = nodeListToArray(this._attributesSidebarList.childNodes).concat(nodeListToArray(this._methodsSidebarList.childNodes));
  var firstSidebarItem = allSidebarChildren[firstVisibleIndex];
  var lastSidebarItem = allSidebarChildren[lastVisibleIndex];

  var firstSidebarTop = firstSidebarItem.offsetTop + 1;
  var lastSidebarBottom = lastSidebarItem.offsetTop + lastSidebarItem.offsetHeight - 2;
  var height = lastSidebarBottom - firstSidebarTop;

  this._placemarker.style.top = firstSidebarTop + 'px';
  this._placemarker.style.height = height + 'px';
};

ClassPage.prototype._updateInterfaceElements = function() {
  this._attributesList.innerHTML = '';
  this._methodsList.innerHTML = '';
  this._attributesSidebarList.innerHTML = '';
  this._methodsSidebarList.innerHTML = '';
  this._titleElement.innerHTML = '';
  this._interfaceListItem.interface = null;

  if (!this.interfaceData) {
    return;
  }

  this.element.querySelectorAll('.attributes').forEach(function(attributesElement) {
    attributesElement.style.display = this._attributes.length === 0 ? 'none' : 'block';
  });

  this.element.querySelectorAll('.methods').forEach(function(methodsElement) {
    methodsElement.style.display = this._methods.length === 0 ? 'none' : 'block';
  });

  this._titleElement.innerText = this.interfaceData.name;
  this._interfaceListItem.interfaceData = this.interfaceData;

  this._methods.forEach(function(method) {
    this._addMemberElements(method, this._methodsList, this._methodsSidebarList);
  }, this);
  this._attributes.forEach(function(attribute) {
    this._addMemberElements(attribute, this._attributesList, this._attributesSidebarList);
  }, this);
};

ClassPage.prototype._addMemberElements = function(member, list, sidebarList) {
  var listItem = new InterfaceListItem();
  listItem.interfaceData = member;
  var showClass = (member.ownerId != this.interfaceData.id);
  listItem.isHeaderClickable = showClass;
  listItem.showOwnerClass = showClass;
  listItem.addEventListener(InterfaceListItem.CLICKED_INTERFACE, this._onClickMember);
  list.appendChild(listItem.element);

  var sidebarItem = document.createElement('li');
  sidebarItem.innerText = member.name;
  sidebarItem.classList.add(member.interfaceType);
  sidebarItem.classList.add('ellipsize');
  sidebarList.appendChild(sidebarItem);

  sidebarItem.onclick = function() {
    this._scrollToMember(member);

    if (self.currentMember === member) {
      return;
    }
    self.currentMember = member;
  };
};

ClassPage.prototype._onClickMember = function(event) {
  member = event.detail.interfaceData;
  var classPage = new ClassPage();
  classPage.interfaceData = member.owner;
  classPage.currentMember = member;
  WebDocs.pageStack.push(classPage, true);
};

ClassPage.prototype._scrollToMember = function(member) {
  if (!member) {
    return;
  }

  var dataArray, list;
  switch (member.interfaceType) {
  case 'attribute':
    dataArray = this._attributes;
    list = this._attributesList;
    break;
  case 'method':
    dataArray = this._methods;
    list = this._methodsList;
  }

  var index = dataArray.indexOf(member);
  if (index === -1) {
    return;
  }

  var element = list.childNodes.item(index);
  if (!element) {
    return;
  }

  this._centerElementOnPage(element);
};

ClassPage.prototype._centerElementOnPage = function(element) {
  var itemRect = element.getBoundingClientRect();

  // Wait until the page is loaded
  if (itemRect.width === 0 || itemRect.height === 0) {
    window.setTimeout(function() {
      this._centerElementOnPage(element);
    }, 0);
    return;
  }

  var targetY = this._contentContainer.scrollTop + itemRect.top + (itemRect.height / 2);
  var newScrollY = targetY - (this._contentContainer.clientHeight / 2);
  this._scrollingProgrammatically = true;
  this._contentContainer.scrollTop = newScrollY;
};

ClassPage.prototype._findMember = function(memberName) {
  if (!this._attributes || !this._methods || !memberName) {
    return null;
  }

  var lowercaseMemberName = memberName.toLowerCase();
  var allMembers = this._attributes.concat(this._methods);
  allMembers.forEach(function(member) {
    if (member.name.toLowerCase() == lowercaseMemberName) {
      return member;
    }
  });

  return null;
};