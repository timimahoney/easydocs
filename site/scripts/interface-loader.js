var InterfaceLoader = {

  loadInterfaces: function(callback) {
    this._loadWebdocsInterfaces(function(interfaces) {
      callback(interfaces);
    });
  },

  _loadWebdocsInterfaces: function(callback) {
    var request = new XMLHttpRequest();
    request.open('GET', '/data/interfaces.xml');
    request.responseType = 'document';
    request.onreadystatechange = function(event) {
      if (request.readyState != XMLHttpRequest.DONE) {
        return;
      }

      var response = request.responseXML;

      if (!response) {
        console.log('Could not load interface data.');
        return;
      }

      var interfaces = InterfaceLoader._parseWebdocsInterfaces(response);
      InterfaceLoader._connectParentInterfaces(interfaces);
      callback(interfaces);
    };

    request.send();
  },

  _connectParentInterfaces: function(interfaces) {
    var interfaceById = {};
    interfaces.forEach(function(thisInterface) {
      interfaceById[thisInterface.id] = thisInterface;
    });

    interfaces.forEach(function(thisInterface) {
      var parent = interfaceById[thisInterface.parentId];
      if (!parent || parent.id == thisInterface.id) {
        return;
      }
      thisInterface.parent = parent;
    });
  },

  _parseWebdocsInterfaces: function(xml) {
    var interfaces = [];

    var interfacesXML = nodeListToArray(xml.getElementsByTagName('interface'));
    interfacesXML.forEach(function(interfaceXML) {
      var thisInterface = this._parseWebdocsInterfaceXML(interfaceXML);
      interfaces.push(thisInterface);
    }, this);

    return interfaces;
  },

  _parseWebdocsInterfaceXML: function(xml) {
    var parsedInterface = {};

    parsedInterface.id = xml.attributes['id'].value;
    parsedInterface.name = xml.attributes['name'].value;
    parsedInterface.description = xml.attributes['description'].value;
    parsedInterface.fullUrl = xml.attributes['full_url'].value;
    if (xml.attributes['parent_id']) {
      parsedInterface.parent_id = xml.attributes['parent_id'].value;
    }
    parsedInterface.interfaceType = 'class';

    var attributeNodes = nodeListToArray(xml.getElementsByTagName('property'));
    parsedInterface.attributes = attributeNodes.map(function(node) {
      var attribute = this._parseAttribute(node);
      attribute.owner = parsedInterface;
      return attribute;
    }, this);

    var methodNodes = nodeListToArray(xml.getElementsByTagName('method'));
    parsedInterface.methods = methodNodes.map(function(node) {
      var method = this._parseMethod(node);
      method.owner = parsedInterface;
      return method;
    }, this);

    return parsedInterface;
  },

  _parseAttribute: function(node) {
    var attribute = {};
    attribute.interfaceType = 'attribute';
    attribute.id = node.attributes['id'].value;
    attribute.type = node.attributes['type'].value;
    attribute.name = node.attributes['name'].value;
    attribute.readonly = node.attributes['readonly'].value == 'true';
    attribute.description = node.attributes['description'].value;
    attribute.ownerId = node.attributes['owner_id'].value;
    attribute.fullUrl = node.attributes['full_url'].value;
    return attribute;
  },

  _parseMethod: function(node) {
    var method = {};
    method.interfaceType = 'method';
    method.id = node.attributes['id'].value;
    method.name = node.attributes['name'].value;
    method.returnType = node.attributes['return_type'].value;
    method.description = node.attributes['description'].value;
    method.returnDescription = node.attributes['return_description'].value;
    method.ownerId = node.attributes['owner_id'].value;
    method.fullUrl = node.attributes['full_url'].value;

    var parameters = nodeListToArray(node.getElementsByTagName('parameter'));
    method.parameters = parameters.map(function (parameterNode) {
      var parameter = {};
      parameter.id = parameterNode.attributes['id'].value;
      parameter.name = parameterNode.attributes['name'].value;
      parameter.type = parameterNode.attributes['type'].value;
      parameter.optional = parameterNode.attributes['optional'].value == 'true';
      parameter.description = parameterNode.attributes['description'].value;
      parameter.fullUrl = parameterNode.attributes['full_url'].value;
      parameter.ownerId = parameterNode.attributes['owner_id'].value;
      return parameter;
    });

    return method;
  }
};