EasyDocs
========

EasyDocs lets you quickly explore the open web platform API. The application was built entirely using [Ruby in the browser](http://trydecaf.org). This means that it uses only standard web technologies (plus Ruby).

All the data on EasyDocs was retrieved from [WebPlatform.org](http://webplatform.org). To get the data, [this script](https://github.com/timahoney/easydocs/blob/master/data/web-platform-docs.rb) queries the [WebPlatform API](http://docs.webplatform.org/wiki/WPD:API) and outputs an XML file. The [`InterfaceLoader`](https://github.com/timahoney/easydocs/blob/master/site/script/interface_loader.rb)  uses this XML file as its data source.


