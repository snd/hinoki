var events = require('events');

var Promise = require('bluebird');

var dns = Promise.promisifyAll(require('dns'));

var hinoki = require('hinoki');

var emitter = new events.EventEmitter();

emitter.on('any', function(event) {
    console.log(event);
});

var factories = {
    addresses: function(domain) {
        return dns.resolve4Async(domain);
    },
    domains: function(addresses) {
        return Promise.map(addresses, function(address) {
            return dns.reverseAsync(address);
        });
    }
};

var container = {
    factories: factories,
    instances: {
        domain: 'www.google.com'
    },
    emitter: emitter
};

hinoki.inject(container, function(domains) {
    console.log(domains);
});
