var http = require('http');

var inject = require('./inject');

inject(function(requestListener, config) {
    console.log('inject complete');
    var server = http.createServer(requestListener);
    server.listen(config.port);
    console.log('go to port ' + config.port);
});
