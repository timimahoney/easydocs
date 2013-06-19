var InterfaceDatabase = {
  LIMIT: 25,
  interfaces: null,
  classInterfaces: null,
  cachedSearches: {},

  loadInterfaces: function(callback) {
    InterfaceLoader.loadInterfaces(function(interfaces) {
      this.classInterfaces = interfaces;
      this.interfaces = [];
      this.classInterfaces.forEach(function(thisInterface) {
        var results = [thisInterface].concat(thisInterface.attributes).concat(thisInterface.methods);
        this.interfaces = this.interfaces.concat(results);
      }, this);

      if (callback) {
        callback(this.interfaces);
      }
    }.bind(this));
  },

  findInterfaces: function(searchTerm, callback) {
    if (!this.interfaces || !searchTerm || searchTerm.length <= 0) {
      callback([]);
      return;
    }

    searchTerm = searchTerm.toLowerCase();

    var results = this.cachedSearches[searchTerm];
    if (results) {
      var trimmedResults = results.slice(0, this.LIMIT);
      callback(trimmedResults);
      return;
    }

    // We can narrow down the number of interfaces to search through
    // by checking if we have cached results for a partial match of this search term.
    var interfacesToSearch = null;
    for (var i = 0; i < searchTerm.length - 2; i++) {
      var substring = searchTerm.substring(0, i);
      interfacesToSearch = this.cachedSearches[substring];
      if (interfacesToSearch) {
        break;
      }
    }

    if (!interfacesToSearch) {
      interfacesToSearch = this.interfaces;
    }

    var foundInterfaces = this._findInterfaces(searchTerm, interfacesToSearch);
    this.cachedSearches[searchTerm] = foundInterfaces;
    var trimmedResults = foundInterfaces.slice(0, this.LIMIT);
    callback(trimmedResults);
  },

  findInterface: function(name, type) {
    if (!name || !this.interfaces) {
      return null;
    }

    var lowercaseName = name.toLowerCase();
    for (var i = 0; i < this.interfaces.length; i++) {
      var thisInterface = this.interfaces[i];
      if (thisInterface.name.toLowerCase() == lowercaseName && (!type || thisInterface.interfaceType == type)) {
        return thisInterface;
      }
    }

    return null;
  },

  _findInterfaces: function(searchTerm, allInterfaces) {
    if (!allInterfaces) {
      return [];
    }

    var resultsSimilarities = allInterfaces.map(function(thisInterface) {
      var similarity = 0;
      switch (thisInterface.interfaceType) {
      case 'class':
        similarity = this._compareClass(thisInterface, searchTerm);
        break;
      case 'attribute':
        similarity = this._compareAttribute(thisInterface, searchTerm);
        break;
      case 'method':
        similarity = this._compareMethod(thisInterface, searchTerm);
        break;
      }

      return [similarity, thisInterface];
    }, this);

    resultsSimilarities = resultsSimilarities.filter(function(similarityInterface) {
      return similarityInterface[0] > 0;
    });
    resultsSimilarities.sort(function(a, b) {
      return b[0] - a[0];
    });

    var results = resultsSimilarities.map(function(similarityInterface) {
      return similarityInterface[1];
    });

    return results;
  },

  _compareClass: function(thisInterface, searchTerm) {
    return this._compareString(thisInterface.name, searchTerm);
  },

  _compareAttribute: function(attribute, searchTerm) {
    var attributeSimilarity = this._compareString(attribute.name, searchTerm);
    var classSimilarity = this._compareString(attribute.owner.name, searchTerm);
    return attributeSimilarity + (classSimilarity / 4);
  },

  _compareMethod: function(method, searchTerm) {
    var methodSimilarity = this._compareString(method.name, searchTerm);
    var classSimilarity = this._compareString(method.owner.name, searchTerm);
    return methodSimilarity + (classSimilarity / 4);
  },

  _compareString: function(haystack, needle) {
    var similarity = 0;
    var needleFragments = needle.split(/[\.\_ ]/);
    var haystackDowncase = haystack.toLowerCase();
    needleFragments.forEach(function(substring) {
      var substringDowncase = substring.toLowerCase();
      if (haystackDowncase == substringDowncase) {
        similarity += 15;
        return;
      }

      var position = haystackDowncase.indexOf(substringDowncase);
      if (position === 0) {
        similarity += 10;
      } else if (position > 0) {
        similarity += 5;
      }
    });

    return similarity;
  }
};