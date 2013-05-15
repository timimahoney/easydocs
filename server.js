var express = require('express');
var fs = require('fs');
var server = express();
var indexPath = __dirname + '/html/index.html';

server.get('/', function(req, res) {
  console.log('Requested the root URL: ' + req.url);
  res.sendfile(indexPath);
});

server.get('/*', function(req, res) {
  console.log('Requested: ' + req.url);
  var path = __dirname + '/html' + req.url;
  if (fs.existsSync(path)) {
    console.log('File exists.');
    res.sendfile(path);
  } else {
    console.log('File does not exist. Redirecting to index.');
    res.sendfile(indexPath);
  }
});

server.listen(8080);