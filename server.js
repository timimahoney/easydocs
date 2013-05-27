// This is a simple Node server that will run the EasyDocs application.
// Type 'node server.js' to use.
// You must have Node with the Express package installed.

var express = require('express');
var fs = require('fs');
var server = express();
var indexPath = __dirname + '/site/html/index.html';

server.get('/', function(req, res) {
  console.log('Requested the root URL: ' + req.url);
  res.sendfile(indexPath);
});

server.get('/*', function(req, res) {
  console.log('Requested: ' + req.url);
  var path = __dirname + '/site' + req.url;
  console.log('Full path: ' + path);
  if (fs.existsSync(path)) {
    console.log('File exists.');
    res.sendfile(path);
  } else {
    console.log('File does not exist. Redirecting to index.');
    res.sendfile(indexPath);
  }
});

server.listen(8080);