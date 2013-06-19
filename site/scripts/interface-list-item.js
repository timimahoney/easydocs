window.InterfaceListItem = function() {
  this.element = document.createElement('li');
  this.element.classList.add('interface-list-item');

  this._titleContainer = document.createElement('div');
  this._titleContainer.classList.add('interface-header');
  this._ownerClass = document.createElement('span');
  this._ownerClass.classList.add('owner-class');
  this._titleContainer.appendChild(this._ownerClass);
  this._title = document.createElement('span');
  this._title.classList.add('interface-name');
  this._titleContainer.appendChild(this._title);
  this._titleContainer.onclick = this._onClickInterface.bind(this);
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

InterfaceListItem.prototype.CLICKED_INTERFACE = 'clicked interface';

Object.defineProperty(InterfaceListItem.prototype, 'interfaceData', {
  get: function() {
    return this._interface;
  },
  set: function(newValue) {
    this._interface = newValue;

    if (!newValue) {
      return;
    }

    this.element.classList.remove('class', 'method', 'attribute');
    this.element.classList.add(this._interface.interfaceType);

    this._updateHeader();
    this._updateDescription();
    this._updateDeclaration();
    this._updateInfo();
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
    return this._showOwnerClass;
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
  this._title.innerText = this._interface.name;

  if (this._interface.owner) {
    this._ownerClass.innerText = this._interface.owner.name;
  } else {
    this._ownerClass.innerHTML = '';
  }
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
    returnTypeElement.innerText = this._interface.returnType;
    this._appendMethodSignature();
    break;
  case 'attribute':
    returnTypeElement.innerText = this._interface.type;
    var name = document.createElement('span');
    name.innerText = this._interface.name;
    this._declaration.appendChild(name);
    break;
  }
};

InterfaceListItem.prototype._appendMethodSignature = function() {
  var methodName = document.createElement('span');
  methodName.innerText = this._interface.name;
  this._declaration.appendChild(methodName);

  var parameters = document.createElement('span');
  parameters.classList.add('parameters');
  this._interface.parameters.forEach(function(parameter) {
    var paramSpan = document.createElement('span');
    paramSpan.classList.add('parameter');
    paramSpan.innerText = parameter.name;
    parameters.appendChild(paramSpan);
  });
  this._declaration.appendChild(parameters);
};

InterfaceListItem.prototype._updateDescription = function() {
  this._description.innerHTML = this._interface.description;
};

InterfaceListItem.prototype._updateInfo = function() {
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
    name.innerText = parameter.name;
    code.appendChild(name);
    var type = document.createElement('span');
    type.classList.add('parameter-type');
    type.innerText = parameter.type;
    code.appendChild(type);
    listItem.appendChild(code);

    var description = document.createElement('div');
    description.classList.add('parameter-description');
    description.innerHTML = parameter.description;
    listItem.appendChild(description);

    this._methodInfo.appendChild(listItem);
  }, this);
};

InterfaceListItem.prototype._onClickInterface = function() {
  if (!isHeaderClickable) {
    return;
  }

  var clickInterfaceEvent = new CustomEvent(this.CLICKED_INTERFACE, { detail: self });
  this.element.dispatchEvent(clickInterfaceEvent);
};