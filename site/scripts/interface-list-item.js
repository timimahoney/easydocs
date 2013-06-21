window.InterfaceListItem = function() {
  this.element = document.createElement('li');
  this.element.classList.add('interface-list-item');

  this._titleContainer = document.createElement('a');
  this._titleContainer.classList.add('interface-header');
  this._title = document.createElement('span');
  this._title.classList.add('interface-name');
  this._titleContainer.appendChild(this._title);
  this._titleContainer.onclick = this._onClickInterface.bind(this);
  this._ownerClass = document.createElement('span');
  this._ownerClass.classList.add('owner-class');
  this._titleContainer.appendChild(this._ownerClass);
  this.element.appendChild(this._titleContainer);

  this._content = document.createElement('div');
  this._content.classList.add('interface-content');
  this.element.appendChild(this._content);

  this._description = document.createElement('div');
  this._description.classList.add('description');
  this._content.appendChild(this._description);

  this._declarationContainer = document.createElement('div');
  this._declarationContainer.classList.add('declaration');
  this._content.appendChild(this._declarationContainer);

  this._declaration = document.createElement('code');
  this._declaration.classList.add('method-signature');
  this._declarationContainer.appendChild(this._declaration);

  this._methodInfo = document.createElement('ol');
  this._methodInfo.classList.add('method-info');
  this._declarationContainer.appendChild(this._methodInfo);

  this.isHeaderClickable = true;
};

InterfaceListItem.CLICKED_INTERFACE = 'clicked interface';

Object.defineProperty(InterfaceListItem.prototype, 'interfaceData', {
  get: function() {
    return this._interface;
  },
  set: function(newValue) {
    this._interface = newValue;

    if (!newValue) {
      return;
    }

    this.element.classList.remove('class');
    this.element.classList.remove('method');
    this.element.classList.remove('attribute');
    this.element.classList.add(this._interface.interfaceType);

    this._updateHeader();
    this._updateDescription();
    this._updateDeclaration();
    this._updateMethodInfo();
  }
});

Object.defineProperty(InterfaceListItem.prototype, 'showOwnerClass', {
  get: function() {
    return this._showOwnerClass;
  },
  set: function(showOwnerClass) {
    this._showOwnerClass = showOwnerClass;
    if (this._showOwnerClass) {
      this.element.classList.add('show-owner');
    } else {
      this.element.classList.remove('show-owner');
    }
  }
});

Object.defineProperty(InterfaceListItem.prototype, 'isHeaderClickable', {
  get: function() {
    return this._isHeaderClickable;
  },
  set: function(isHeaderClickable) {
    this._isHeaderClickable = isHeaderClickable;
    if (this._isHeaderClickable) {
      this.element.classList.add('clickable');
    } else {
      this.element.classList.remove('clickable');
    }
  }
});

InterfaceListItem.prototype._updateHeader = function() {
  this._title.innerHTML = this._interface.name;

  var websterUrl = '/class/';

  if (this._interface.owner) {
    websterUrl += this._interface.owner.name + '/';
    this._ownerClass.innerHTML = this._interface.owner.name;
  } else {
    this._ownerClass.innerHTML = '';
  }

  websterUrl += this._interface.name;
  this._titleContainer.href = websterUrl;
};

InterfaceListItem.prototype._updateDeclaration = function() {
  var type = this._interface.interfaceType;
  this._declaration.innerHTML = '';

  if (type == 'class') {
    return;
  }

  // FIXME: Link the attribute types, method return types,
  // and method parameter types to their class pages.
  var returnTypeElement = document.createElement('span');
  returnTypeElement.classList.add('return-type');
  this._declaration.appendChild(returnTypeElement);
  if (this._interface.readonly) {
    this._declaration.classList.add('readonly');
  }

  switch (type) {
  case 'method':
    returnTypeElement.innerHTML = this._interface.returnType;
    this._appendMethodSignature();
    break;
  case 'attribute':
    returnTypeElement.innerHTML = this._interface.type;
    var name = document.createElement('span');
    name.innerHTML = this._interface.name;
    this._declaration.appendChild(name);
    break;
  }
};

InterfaceListItem.prototype._appendMethodSignature = function() {
  var methodName = document.createElement('span');
  methodName.innerHTML = this._interface.name;
  this._declaration.appendChild(methodName);

  var parameters = document.createElement('span');
  parameters.classList.add('parameters');
  this._interface.parameters.forEach(function(parameter) {
    var paramSpan = document.createElement('span');
    paramSpan.classList.add('parameter');
    paramSpan.innerHTML = parameter.name;
    if (parameter.optional) {
      paramSpan.classList.add('optional');
    }
    parameters.appendChild(paramSpan);
  });
  this._declaration.appendChild(parameters);
};

InterfaceListItem.prototype._updateDescription = function() {
  this._description.innerHTML = this._interface.description;
};

InterfaceListItem.prototype._updateMethodInfo = function() {
  this._methodInfo.innerHTML = '';
  if (this._interface.interfaceType != 'method') {
    return;
  }

  var items = this._interface.parameters.slice();
  if (this._interface.returnType != 'void' && this._interface.returnDescription.length > 0) {
    items.push({
      name: 'return',
      type: this._interface.returnType,
      description: this._interface.returnDescription,
      isReturn: true
    });
  }

  items.forEach(function(parameter) {
    if (parameter.description.length <= 0) {
      return;
    }

    var listItem = document.createElement('li');
    if (parameter.isReturn) {
      listItem.classList.add('return');
    }

    var code = document.createElement('code');
    var name = document.createElement('span');
    name.classList.add('parameter-name');
    name.innerHTML = parameter.name;
    code.appendChild(name);
    var type = document.createElement('span');
    type.classList.add('parameter-type');
    type.innerHTML = parameter.type;
    code.appendChild(type);

    if (parameter.optional) {
      var optional = document.createElement('span');
      optional.classList.add('parameter-optional');
      optional.innerHTML = '(optional)';
      code.appendChild(optional);
    }

    listItem.appendChild(code);

    var description = document.createElement('div');
    description.classList.add('parameter-description');
    description.innerHTML = parameter.description;
    listItem.appendChild(description);

    this._methodInfo.appendChild(listItem);
  }, this);
};

InterfaceListItem.prototype._onClickInterface = function(event) {
  if (!this.isHeaderClickable) {
    return;
  }

  // Allow them to open the link in a new window or tab.
  if (event.metaKey || event.ctrlKey) {
    return;
  }

  event.preventDefault();
  var clickInterfaceEvent = new CustomEvent(InterfaceListItem.CLICKED_INTERFACE, { detail: this });
  this.element.dispatchEvent(clickInterfaceEvent);
};