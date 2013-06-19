console.log('Running helpers.js');

function defaultIfUndefinedOrNull(object, defaultValue) {
  if (typeof object === 'undefined' || object === null) {
    return defaultValue;
  }

  return object;
}

function nodeListToArray(nodeList) {
  return Array.prototype.slice.call(nodeList);
}