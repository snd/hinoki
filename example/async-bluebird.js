var Promise = require('bluebird');

var dns = Promise.promisifyAll(require('dns'));

var hinoki = require('hinoki');

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

var instances = {
    domain: 'www.google.com'
};

var container = hinoki.newContainer(factories, instances);

container.emitter.on('any', console.log);

hinoki.inject(container, function(domains) {
    console.log(domains);
});
