var dns = require('dns');

var q = require('q');
var hinoki = require('hinoki');

var factories = {
    addresses: function(domain) {
        return q.nfcall(dns.resolve4, domain);
    },
    domains: function(addresses) {
        return q.all(addresses.map(function(address) {
            return q.nfcall(dns.reverse, address);
        }));
    }
};

var instances = {
    domain: 'www.google.com'
};

var container = hinoki.newContainer(factories, instances);

hinoki.inject(container, function(domains) {
    console.log(domains);
});
